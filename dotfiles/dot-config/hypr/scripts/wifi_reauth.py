#!/usr/bin/env python3
# Author: Magnus Naessan Gaarder
# Prompt for a new wifi password when the saved one is rejected.
#
# NetworkManager won't make nm-applet show a dialog in this situation: it asks for
# "new secrets", nm-applet answers with the same saved password from the keyring, and
# the connection just keeps failing. Instead, this follows wpa_supplicant's journal
# (its D-Bus signals are root-only) to spot a rejected password within ~1s, asks with
# zenity, saves the answer where the old secret lived, and reconnects. Cancelling
# leaves the saved password untouched.
import subprocess
import time

import gi

gi.require_version("NM", "1.0")
from gi.repository import Gio, GLib, NM

COOLDOWN = 120  # seconds before the same connection may prompt again after a cancel
# wpa_supplicant lines that mean the credentials (not the radio) were the problem
REJECT_MARKERS = ("CTRL-EVENT-EAP-FAILURE", "error 691", "reason=WRONG_KEY",
                  "pre-shared key may be incorrect")
S = NM.DeviceState
ACTIVATING = (S.PREPARE, S.CONFIG, S.NEED_AUTH, S.IP_CONFIG)

client = NM.Client.new(None)
prompting = set()  # connection uuids with a dialog open
last_prompt = {}  # uuid -> monotonic time the last dialog was cancelled
attempting = {}  # iface -> uuid of the connection being activated (gone from the device once it fails)


def secret_key(conn):
    """(setting-name, setting-key, agent_owned) of the password this connection uses."""
    s = conn.get_setting_802_1x()
    if s:
        return "802-1x", "password", bool(s.get_password_flags() & NM.SettingSecretFlags.AGENT_OWNED)
    s = conn.get_setting_wireless_security()
    if s and s.get_key_mgmt() in ("wpa-psk", "sae"):
        return ("802-11-wireless-security", "psk",
                bool(s.get_psk_flags() & NM.SettingSecretFlags.AGENT_OWNED))
    return None


def save_and_connect(conn, device, password):
    setting, key, agent_owned = secret_key(conn)
    if agent_owned:
        # Same item nm-applet stores, so it hands this one to NM from now on
        subprocess.run(["secret-tool", "store", f"--label=Network secret for {conn.get_id()}/{setting}/{key}",
                        "xdg:schema", "org.freedesktop.NetworkManager.Connection",
                        "connection-uuid", conn.get_uuid(), "setting-name", setting, "setting-key", key],
                       input=password.encode(), check=False)
        client.activate_connection_async(conn, device, None, None, None, None)
    else:
        conn.get_setting_by_name(setting).set_property(key.replace("-", "_"), password)
        conn.commit_changes_async(True, None,
                                  lambda c, r: (c.commit_changes_finish(r),
                                                client.activate_connection_async(c, device, None, None, None, None)))


def prompt(conn, device):
    uuid = conn.get_uuid()
    if uuid in prompting or time.monotonic() - last_prompt.get(uuid, -COOLDOWN) < COOLDOWN:
        return
    prompting.add(uuid)
    proc = Gio.Subprocess.new(
        ["zenity", "--entry", "--hide-text", "--title=Wi-Fi password",
         f"--text=The password for \"{conn.get_id()}\" was rejected.\nEnter it again to connect:",
         "--ok-label=Connect"],
        Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_SILENCE)

    def done(p, res):
        prompting.discard(uuid)
        _, out, _ = p.communicate_utf8_finish(res)
        password = (out or "").rstrip("\n")
        if p.get_exit_status() == 0 and password:
            last_prompt.pop(uuid, None)
            save_and_connect(conn, device, password)
        else:
            last_prompt[uuid] = time.monotonic()

    proc.communicate_utf8_async(None, None, done)


def prompt_for(device):
    conn = client.get_connection_by_uuid(attempting.get(device.get_iface(), ""))
    if conn and secret_key(conn):
        prompt(conn, device)


def on_rejected(iface):
    device = client.get_device_by_iface(iface)
    if isinstance(device, NM.DeviceWifi) and device.get_state() in ACTIVATING:
        prompt_for(device)


def on_line(stream, res):
    line, _ = stream.read_line_finish_utf8(res)
    if line is None:
        loop.quit()  # journalctl died; the next login starts us again
        return
    if any(m in line for m in REJECT_MARKERS) and ":" in line:
        on_rejected(line.split(":", 1)[0].strip())
    stream.read_line_async(GLib.PRIORITY_DEFAULT, None, on_line)


def on_state(device, new, old, reason):
    if new == S.PREPARE:
        ac = device.get_active_connection()
        if ac:
            attempting[device.get_iface()] = ac.get_uuid()
    # Nothing saved at all during autoconnect: NM fails with NO_SECRETS without ever
    # reaching wpa_supplicant, so prompt for that case here.
    elif new == S.FAILED and reason == NM.DeviceStateReason.NO_SECRETS:
        prompt_for(device)


journal = Gio.Subprocess.new(["journalctl", "-f", "-n0", "-o", "cat", "-u", "wpa_supplicant.service"],
                             Gio.SubprocessFlags.STDOUT_PIPE)
Gio.DataInputStream.new(journal.get_stdout_pipe()).read_line_async(GLib.PRIORITY_DEFAULT, None, on_line)
for d in client.get_devices():
    if isinstance(d, NM.DeviceWifi):
        d.connect("state-changed", on_state)

loop = GLib.MainLoop()
loop.run()
