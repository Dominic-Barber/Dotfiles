#!/bin/bash
PIDFILE="/tmp/autoclick.pid"

if [ -f "$PIDFILE" ]; then
    PID=$(cat "$PIDFILE")
    kill "$PID"
    rm "$PIDFILE"
else
    echo $$ > "$PIDFILE"
    while true; do
        # 1. Dispatch Left Click DOWN
        hyprctl dispatch 'hl.dsp.send_key_state({ mods = "", key = "mouse:272", state = "down" })'
        
        # 2. Dispatch Left Click UP
        hyprctl dispatch 'hl.dsp.send_key_state({ mods = "", key = "mouse:272", state = "up" })'
        
        sleep 0.01
    done
fi

