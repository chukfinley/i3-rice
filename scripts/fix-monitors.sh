#!/bin/bash
# One-shot fixer: consolidate monitor handling into a SINGLE idempotent script,
# remove the conflicting DWM-era handler, break the live flicker loop, and apply
# the correct layout now. Needs sudo once (the udev rule is root-owned).
#
# Run:  bash ~/git/i3-rice/scripts/fix-monitors.sh
set -e

REPO="/home/user/git/i3-rice"
BIN="/home/user/.local/bin"

echo ">> Installing single udev trigger -> dock-layout.sh ..."
sudo tee /etc/udev/rules.d/95-monitor-hotplug.rules >/dev/null <<'EOF'
# Single monitor-hotplug trigger. Calls the idempotent dock-layout.sh, which is
# the one source of truth for layout + workspace assignment. (Was: DWM-era
# monitor-hotplug.sh, which fought i3's dock-layout.sh and self-looped.)
ACTION=="change", SUBSYSTEM=="drm", RUN+="/bin/su user -c 'DISPLAY=:0 /home/user/.local/bin/dock-layout.sh'"
EOF
sudo udevadm control --reload-rules

echo ">> Disabling the old DWM monitor-hotplug.sh (kept as .disabled) ..."
HP="/home/user/.config/dwm/scripts/monitor-hotplug.sh"
[[ -f "$HP" ]] && mv -f "$HP" "$HP.disabled"

echo ">> Ensuring scripts are installed and executable ..."
chmod +x "$REPO/scripts/dock-layout.sh" "$REPO/scripts/i3-monitor-daemon" \
         "$REPO/scripts/i3-assign-workspaces" "$REPO/scripts/i3-workspace-per-monitor"
ln -sf "$REPO/scripts/dock-layout.sh"            "$BIN/dock-layout.sh"
ln -sf "$REPO/scripts/i3-monitor-daemon"         "$BIN/i3-monitor-daemon"
ln -sf "$REPO/scripts/i3-assign-workspaces"      "$BIN/i3-assign-workspaces"
ln -sf "$REPO/scripts/i3-workspace-per-monitor"  "$BIN/i3-workspace-per-monitor"

echo ">> Breaking the live flicker loop (killing all competing handlers) ..."
pkill -f 'i3-monitor-daemon'  2>/dev/null || true
pkill -f 'monitor-hotplug.sh' 2>/dev/null || true
pkill -x xev                  2>/dev/null || true
pkill -f 'dock-layout.sh'     2>/dev/null || true
rm -f /tmp/i3-monitor-daemon.pid /tmp/dock-layout.lock
sleep 1

echo ">> Applying correct layout now ..."
"$BIN/dock-layout.sh"

echo ">> Starting crash-resistant monitor daemon ..."
setsid "$BIN/i3-monitor-daemon" >/dev/null 2>&1 < /dev/null &

echo ">> Done. One script now owns the layout: $BIN/dock-layout.sh"
echo "   Try unplug/replug the dock — it should settle without flicker."
