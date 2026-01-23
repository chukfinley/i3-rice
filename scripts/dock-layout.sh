#!/bin/bash
# Configure monitor layout when docking
export DISPLAY=:0
export XAUTHORITY=/home/user/.Xauthority

# Force DPMS on (wake all monitors)
xset dpms force on
sleep 1  # give MST hub a moment

# Check which DP-3 outputs exist
EXTERNAL_MONITORS=()
for OUT in DP-3-1 DP-3-2 DP-3-3; do
    if xrandr | grep -q "^$OUT connected"; then
        EXTERNAL_MONITORS+=($OUT)
    fi
done

# Keep laptop screen on, externals go above it
xrandr --output eDP-1 --auto --primary

# Enable external monitors and set layout
for i in "${EXTERNAL_MONITORS[@]}"; do
    xrandr --output $i --auto
done

# Position external monitors above laptop
xrandr --output DP-3-1 --auto --above eDP-1
xrandr --output DP-3-2 --auto --right-of DP-3-1

# Extra safeguard: force DPMS on again
xset dpms force on

# Optional retry loop (fixes slow MST wake)
for i in 1 2; do
    for OUT in "${EXTERNAL_MONITORS[@]}"; do
        xrandr --output $OUT --auto
    done
    sleep 0.5
done

# Restore wallpaper and refresh i3
[[ -x ~/.fehbg ]] && ~/.fehbg
i3-msg restart 2>/dev/null || true
