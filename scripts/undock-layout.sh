#!/bin/sh
# Configure monitor layout when undocking
export DISPLAY=:0
export XAUTHORITY=/home/user/.Xauthority

# Basic fallback when dock is unplugged
xrandr --output eDP-1 --auto --primary \
       --output DP-3-1 --off \
       --output DP-3-2 --off \
       --output DP-3-3 --off
