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

# Build a single xrandr command for the desired layout.
# Start with laptop as primary, then add whatever external monitors exist.
XRANDR_ARGS=(--output eDP-1 --auto --primary)

for OUT in DP-3-1 DP-3-2 DP-3-3; do
    if echo "$XRANDR_STATUS" | grep -q "^$OUT connected"; then
        case "$OUT" in
            DP-3-1) XRANDR_ARGS+=(--output "$OUT" --auto --above eDP-1) ;;
            DP-3-2) XRANDR_ARGS+=(--output "$OUT" --auto --right-of DP-3-1) ;;
            *)      XRANDR_ARGS+=(--output "$OUT" --auto) ;;
        esac
    else
        # Explicitly turn off disconnected outputs
        XRANDR_ARGS+=(--output "$OUT" --off)
    fi
done

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
