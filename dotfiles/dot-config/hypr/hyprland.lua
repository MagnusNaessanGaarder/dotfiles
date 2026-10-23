-- Maintained by Magnus Naessan Gaarder, based on work by Filip R. Spanne
-- Translated from filip-rs/arch-dotfiles: dotfiles/dot-config/hypr/hyprland.conf
-- Target: Hyprland 0.55+ Lua config (~/.config/hypr/hyprland.lua)
--
-- Cross-checked against a confirmed hl.* API reference (source-derived from Hyprland
-- itself) and against the actual runtime errors Hyprland raised while testing this
-- config. Remaining genuine uncertainty is called out inline with "VERIFY".

------------------
---- MONITORS ----
------------------
-- Original: monitor=HDMI-A-1,1920x1080@60, auto, 1.25, mirror, eDP-1
-- "mirror" is a confirmed hl.monitor() field (output name to mirror).
-- Layouts saved from the Monitors popup (SUPER+CTRL+M) go to monitors.lua, which is
-- machine-specific and not in git; without it, fall back to the laptop panel.
if not pcall(require, "monitors") then
	hl.monitor({
		output = "eDP-1",
		mode = "preferred",
		position = "0x0",
		scale = 1.25,
	})
end

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
	hl.exec_cmd("blueman-applet") -- systray app for BT
	hl.exec_cmd("nm-applet --indicator") -- systray app for Network/Wifi; also the NM secret agent (stores wifi passwords in gnome-keyring)
	hl.exec_cmd("~/.config/hypr/scripts/wifi_reauth.py") -- re-prompt for wifi password when autoconnect is rejected (NM blocks dialogs during autoconnect)
	hl.exec_cmd("awww-daemon") -- start awww, then set the wallpaper once the daemon is up
	hl.exec_cmd("~/.config/hypr/scripts/wallpaper_rotate.sh boot") -- random wallpaper from $WALLPAPER_DIR; starts the timer if timed mode is on
	hl.exec_cmd("hyprpm reload -n")
	hl.exec_cmd("swaync")
	hl.exec_cmd("waybar")
	hl.exec_cmd("nwg-dock-hyprland -d -nolauncher") -- app dock, hidden until the mouse touches the bottom edge
	hl.dispatch(hl.dsp.focus({ workspace = 3 }))
	hl.exec_cmd("hypridle")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
	hl.exec_cmd("~/.config/hypr/scripts/quickshell/music/equalizer.sh apply")
	hl.exec_cmd("sh -c 'sleep 3; exec brave --no-startup-window'") -- preload brave hidden so SUPER+W opens a window instantly (stays resident after the last window closes)
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("GTK_THEME", "Catppuccin-Mauve-Dark")
hl.env("WALLPAPER_DIR", "~/Pictures/Wallpapers")
hl.env("SCRIPT_DIR", "~/.config/hypr/scripts")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("GDK_SCALE", "1")
hl.env("XCURSOR_SIZE", "21")
hl.env("GDK_DPI_SCALE", "1")

-----------------------------------------
---- LOOK AND FEEL / CORE VARIABLES  ----
-----------------------------------------
-- NOTE: original file did `col.active_border = $theme_border` etc, sourced from a
-- generated colors.conf (hyprlang variables). That file is gitignored/machine-generated,
-- reconstructed here as colors.lua (see that file for the real variable names, taken
-- directly from scripts/theme_apply.sh) -- put it next to this file and require it:
local colors = require("colors")
-- Machine-specific overrides (was `source = local.conf`) -- put local.lua next to
-- this file too (empty is fine). Call require() as a bare statement here, not
-- assigned to a variable -- "local" is a reserved Lua keyword, so
-- `local local = require("local")` would be a syntax error.
require("local")

hl.config({
	general = {
		gaps_in = 4,
		gaps_out = 7,
		border_size = 1,
		col = {
			active_border = colors.theme_border,
			inactive_border = colors.theme_border_inactive,
		},
		layout = "dwindle",
	},

	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		animate_manual_resizes = true,
		vrr = 0,
	},

	decoration = {
		rounding = colors.theme_rounding,
		blur = {
			enabled = true,
			size = 3,
			passes = 4,
			new_optimizations = true,
		},
	},

	dwindle = {
		preserve_split = true,
	},

	master = {
		-- new_is_master = true,
	},

	-- kb_model/kb_rules were blank in the original conf (no value after "=").
	-- That's an empty string, not an empty table.
	input = {
		kb_layout = "us,no",
		kb_model = "",
		kb_variant = "altgr-intl",
		kb_options = "",
		kb_rules = "",
		follow_mouse = 1,
		force_no_accel = true,
		sensitivity = -0.35,
		touchpad = {
			tap_to_click = false,
			natural_scroll = true,
			disable_while_typing = true,
			scroll_factor = 0.6,
		},
	},

	-- Confirmed valid hl.config() categories (verified two ways: they appear in the
	-- source-derived API reference, and hyprconf2lua -- a dedicated conversion tool --
	-- independently produced the same category names).
	xwayland = {
		force_zero_scaling = true,
	},
	ecosystem = {
		no_update_news = true,
	},
})

-- Per-device override (touchpad sensitivity)
hl.device({
	name = "asup1204:00-093a:2642-touchpad",
	sensitivity = 0.1,
})

-- Workspace-to-monitor assignments -- confirmed shape: hl.workspace_rule({ workspace,
-- monitor?, persistent?, ... }). "workspace" wants a string selector.
hl.workspace_rule({ workspace = "1", monitor = "eDP-1", persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "eDP-1", persistent = true })
-- hl.workspace_rule({ workspace = "3", monitor = "eDP-1", persistent = true })
-- hl.workspace_rule({ workspace = "4", monitor = "eDP-1", persistent = true })
-- hl.workspace_rule({ workspace = "5", monitor = "eDP-1", persistent = true })
-- hl.workspace_rule({ workspace = "6", monitor = "eDP-1", persistent = true })
-- hl.workspace_rule({ workspace = "7", monitor = "eDP-1", persistent = true })
-- hl.workspace_rule({ workspace = "8", monitor = "eDP-1", persistent = true })
-- hl.workspace_rule({ workspace = "9", monitor = "eDP-1", persistent = true })
-- hl.workspace_rule({ workspace = "10", monitor = "eDP-1", persistent = true })


-------------------
---- GESTURES  ----
-------------------
-- hl.gesture() registers an individual touch/touchpad gesture (separate from the
-- `gestures` hl.config() category below, which holds general gesture settings).
hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

hl.config({
	gestures = {
		workspace_swipe_forever = true,
	},
})

----------------------------------
---- SPLIT-OUT CONFIG MODULES ----
----------------------------------
-- Hyprland Lua configs are split with require(), not `source`. Save each
-- corresponding .lua file next to this one (no .lua extension in the call):
require("animations")
require("keybindings")
require("windowrules")
require("hyprgrass")
