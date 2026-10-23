#!/usr/bin/env bash
# Author: Magnus Naessan Gaarder
# wallpaper_rotate.sh — random wallpaper on boot + optional timed rotation.
#
# Usage:
#   wallpaper_rotate.sh boot     apply a random wallpaper, start the timer if mode is "timed"
#   wallpaper_rotate.sh next     apply a random wallpaper now
#   wallpaper_rotate.sh toggle   switch between "static" and "timed" mode
#   wallpaper_rotate.sh loop     (internal) the timer loop
#
# Mode persists in ~/.cache/wallpaper_mode. Interval (seconds) is read from
# ~/.cache/wallpaper_interval if present, otherwise DEFAULT_INTERVAL.

SRC_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
SRC_DIR="${SRC_DIR/#\~/$HOME}"
SPLIT_SCRIPT="$HOME/.config/hypr/scripts/wallpaper_split.sh"
MODE_FILE="$HOME/.cache/wallpaper_mode"
INTERVAL_FILE="$HOME/.cache/wallpaper_interval"
LAST_FILE="$HOME/.cache/wallpaper_last"
PID_FILE="${XDG_RUNTIME_DIR:-/tmp}/wallpaper_rotate.pid"
DEFAULT_INTERVAL=900 # 15 minutes

get_mode() { [ -f "$MODE_FILE" ] && cat "$MODE_FILE" || echo "static"; }

get_interval() {
    local i
    i=$(cat "$INTERVAL_FILE" 2>/dev/null)
    [[ "$i" =~ ^[0-9]+$ ]] && [ "$i" -ge 10 ] && echo "$i" || echo "$DEFAULT_INTERVAL"
}

apply_random() {
    # Don't override a video wallpaper picked from the widget
    pgrep -x mpvpaper >/dev/null && return 0

    local last file
    last=$(cat "$LAST_FILE" 2>/dev/null)
    mapfile -t files < <(find "$SRC_DIR" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) ! -path "$last")
    # Only one image in the folder: allow repeating it
    [ "${#files[@]}" -eq 0 ] && [ -f "$last" ] && files=("$last")
    [ "${#files[@]}" -eq 0 ] && return 1

    file=$(printf '%s\n' "${files[@]}" | shuf -n 1)
    echo "$file" > "$LAST_FILE"
    bash "$SPLIT_SCRIPT" "$file" >/dev/null 2>&1
}

loop_running() { [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; }

start_loop() {
    loop_running && return 0
    setsid "$0" loop </dev/null >/dev/null 2>&1 &
}

stop_loop() {
    # setsid made the loop a group leader: kill the group so its sleep dies too
    loop_running && kill -- -"$(cat "$PID_FILE")" 2>/dev/null
    rm -f "$PID_FILE"
}

case "$1" in
    boot)
        # Wait for awww-daemon (started from hyprland.lua) to be ready
        for _ in $(seq 1 25); do awww query >/dev/null 2>&1 && break; sleep 0.2; done
        apply_random
        [ "$(get_mode)" = "timed" ] && start_loop
        ;;
    next)
        apply_random
        ;;
    toggle)
        if [ "$(get_mode)" = "timed" ]; then
            echo "static" > "$MODE_FILE"
            stop_loop
            notify-send -a Wallpaper "Wallpaper: static" "Timed switching is off"
        else
            echo "timed" > "$MODE_FILE"
            start_loop
            notify-send -a Wallpaper "Wallpaper: timed" "Switching every $(( $(get_interval) / 60 )) min"
        fi
        ;;
    loop)
        echo $$ > "$PID_FILE"
        trap 'rm -f "$PID_FILE"; exit 0' TERM INT
        while [ "$(get_mode)" = "timed" ]; do
            sleep "$(get_interval)" &
            wait $!
            [ "$(get_mode)" = "timed" ] && apply_random
        done
        rm -f "$PID_FILE"
        ;;
    *)
        echo "Usage: $0 {boot|next|toggle}" >&2
        exit 1
        ;;
esac
