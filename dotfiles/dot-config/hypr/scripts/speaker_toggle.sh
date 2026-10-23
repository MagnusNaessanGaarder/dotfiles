#!/bin/bash
# Maintained by Magnus Naessan Gaarder, based on work by Filip R. Spanne
SINK="alsa_output.pci-0000_03_00.6.analog-stereo"
CURRENT=$(pactl --format=json list sinks | python3 -c "
import json,sys
for s in json.load(sys.stdin):
    if s['name']=='$SINK':
        print(s['active_port'])
        break
")
if [[ "$CURRENT" == *"headphones"* ]]; then
    pactl set-sink-port "$SINK" analog-output-lineout
    notify-send "Audio: Speakers (Line Out)"
else
    pactl set-sink-port "$SINK" analog-output-headphones
    notify-send "Audio: Headphones"
fi
