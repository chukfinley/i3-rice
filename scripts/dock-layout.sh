#!/bin/bash
# Configure monitor layout when docking.
#
# Uses a SINGLE xrandr call to avoid flooding the RandR event bus.
# The i3-monitor-daemon will detect the change and call
# i3-assign-workspaces automatically — no need to restart i3 here.

export DISPLAY=:0
export XAUTHORITY=/home/user/.Xauthority

# Wake monitors
xset dpms force on
sleep 1  # give MST hub a moment to enumerate outputs

# Query xrandr once to check which outputs are connected
XRANDR_STATUS=$(xrandr)

# Find connected externals
CONNECTED_EXTERNALS=()
for OUT in DP-3-1 DP-3-2 DP-3-3; do
    if echo "$XRANDR_STATUS" | grep -q "^$OUT connected"; then
        CONNECTED_EXTERNALS+=("$OUT")
    fi
done

XRANDR_ARGS=()

if (( ${#CONNECTED_EXTERNALS[@]} > 0 )); then
    # Dock mode: externals only, internal off
    XRANDR_ARGS+=(--output eDP-1 --off)
    PREV=""
    for OUT in DP-3-1 DP-3-2 DP-3-3; do
        if [[ " ${CONNECTED_EXTERNALS[*]} " == *" $OUT "* ]]; then
            if [[ -z "$PREV" ]]; then
                XRANDR_ARGS+=(--output "$OUT" --auto --primary --pos 0x0)
            else
                XRANDR_ARGS+=(--output "$OUT" --auto --right-of "$PREV")
            fi
            PREV="$OUT"
        else
            XRANDR_ARGS+=(--output "$OUT" --off)
        fi
    done
else
    # Undocked: internal only
    XRANDR_ARGS+=(--output eDP-1 --auto --primary)
    for OUT in DP-3-1 DP-3-2 DP-3-3; do
        XRANDR_ARGS+=(--output "$OUT" --off)
    done
fi

# One single xrandr call — one RandR event
xrandr "${XRANDR_ARGS[@]}"

# Wake monitors again (some MST hubs need a nudge after mode-setting)
xset dpms force on

# Restore wallpaper
[[ -x ~/.fehbg ]] && ~/.fehbg

# The daemon handles workspace reassignment automatically.
# Only call i3-assign-workspaces directly if the daemon isn't running.
if ! pgrep -f 'i3-monitor-daemon' >/dev/null; then
    ~/.local/bin/i3-assign-workspaces
fi
