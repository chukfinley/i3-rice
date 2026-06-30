#!/bin/bash
# Monitor layout + workspace assignment — THE single source of truth.
#
# Triggered by:
#   - udev DRM hotplug  -> /etc/udev/rules.d/95-monitor-hotplug.rules
#   - i3-monitor-daemon -> backup for X-only RandR changes (regolith refresh etc.)
#
# WHY IDEMPOTENT (this is the whole point):
#   Every xrandr mode-set emits a DRM `change` / RRScreenChangeNotify event.
#   A handler that reconfigures unconditionally re-triggers itself through the
#   event its own xrandr produced -> endless mode-set loop -> the screens
#   blink forever and never settle (the "Rumbacken"/black-screen bug).
#   This script computes the DESIRED geometry, compares it to the CURRENT
#   geometry, and only calls xrandr when they differ. The self-emitted event
#   then finds the layout already correct -> no-op -> the loop dies.
#
# Lid-aware, supports all three setups:
#   externals + lid OPEN   -> all monitors (externals top row, laptop centered below)
#   externals + lid CLOSED -> externals only
#   no externals           -> laptop only

[[ -z "$HOME" ]] && export HOME=/home/user
export DISPLAY="${DISPLAY:-:0}"
[[ -z "$XAUTHORITY" && -f "$HOME/.Xauthority" ]] && export XAUTHORITY="$HOME/.Xauthority"

LAPTOP="eDP-1"
LOCK="/tmp/dock-layout.lock"

# --force: turn externals off then on before applying, to retrain the DP link.
# Needed at login: kernel/i915 sometimes brings externals up "connected+active"
# but with no signal (black). The idempotency gate would then skip the fix, so
# a forced off/on cycle is the only reliable way to light them. The daemon calls
# this WITHOUT --force (idempotent) to avoid a self-retriggering flicker loop.
FORCE=0
[[ "$1" == "--force" || "$1" == "-f" ]] && FORCE=1

# Serialize concurrent invocations (udev + daemon may fire together).
# -n: if another run holds the lock, skip — it will converge to the same state.
exec 9>"$LOCK"
flock -n 9 || exit 0

# Let an MST hub finish enumerating its outputs before we read the state.
sleep 1

lid_closed() { grep -q closed /proc/acpi/button/lid/LID/state 2>/dev/null; }

# Block until i3 reports the expected number of active outputs (or we time out).
# xrandr returns before i3 has processed the RandR change, so calling
# i3-assign-workspaces immediately would see the OLD output set and skip the
# orphan migration — leaving workspaces stranded on unreachable numbers.
wait_i3_outputs() {
    local want=$1 i n
    for i in $(seq 1 30); do
        n=$(i3-msg -t get_outputs 2>/dev/null | jq '[.[]|select(.active)]|length')
        [[ "$n" == "$want" ]] && return 0
        sleep 0.1
    done
}

# Active geometry, normalized "NAME=WxH+X+Y", sorted. Off/disconnected omitted.
current_geom() {
    xrandr --query | awk '/ connected/{
        name=$1; g="";
        for(i=2;i<=NF;i++) if($i ~ /^[0-9]+x[0-9]+\+[0-9]+\+[0-9]+$/){g=$i;break}
        if(g!="") print name"="g
    }' | sort
}

# Preferred (first listed) mode for an output, e.g. "2560x1080".
pref_mode() {
    xrandr --query | awk -v o="$1" '
        $1==o && / connected/ {f=1; next}
        f && /^[[:space:]]+[0-9]+x[0-9]+/ {print $1; exit}
        f && / connected/ {exit}'
}

# Connected externals, in stable name order (DP-3-1, DP-3-2, ...).
mapfile -t EXT < <(xrandr --query | grep ' connected' | awk '{print $1}' | grep -vx "$LAPTOP" | sort)

# All known outputs (to switch off whatever we don't enable).
mapfile -t ALL < <(xrandr --query | grep -E ' (connected|disconnected)' | awk '{print $1}')

ARGS=()
declare -A ON   # ON[name]=geom for outputs we enable

# Lay EXT left->right at y=0. Sets ROW_W (total width) and ROW_H (max height).
place_row() {
    ROW_W=0; ROW_H=0
    local prev=""
    for o in "${EXT[@]}"; do
        local m w h; m=$(pref_mode "$o"); [[ -z "$m" ]] && m="1920x1080"
        w=${m%x*}; h=${m#*x}
        ON[$o]="${w}x${h}+${ROW_W}+0"
        if [[ -z "$prev" ]]; then
            ARGS+=(--output "$o" --mode "$m" --pos "${ROW_W}x0" --primary)
        else
            ARGS+=(--output "$o" --mode "$m" --pos "${ROW_W}x0")
        fi
        ROW_W=$((ROW_W + w)); (( h > ROW_H )) && ROW_H=$h
        prev="$o"
    done
}

if (( ${#EXT[@]} == 0 )); then
    # Laptop only
    lm=$(pref_mode "$LAPTOP"); [[ -z "$lm" ]] && lm="1920x1080"
    ON[$LAPTOP]="${lm%x*}x${lm#*x}+0+0"
    ARGS+=(--output "$LAPTOP" --mode "$lm" --pos 0x0 --primary)
elif lid_closed; then
    # Externals only (lid shut)
    place_row
else
    # All monitors: externals on top, laptop centered below the LEFT external.
    place_row
    lm=$(pref_mode "$LAPTOP"); [[ -z "$lm" ]] && lm="1920x1080"
    lw=${lm%x*}; lh=${lm#*x}
    # Center under EXT[0] (leftmost external), not under the whole row.
    lext_w=$(pref_mode "${EXT[0]}"); lext_w=${lext_w%x*}; [[ -z "$lext_w" ]] && lext_w=$ROW_W
    lx=$(( (lext_w - lw) / 2 )); (( lx < 0 )) && lx=0
    ON[$LAPTOP]="${lw}x${lh}+${lx}+${ROW_H}"
    ARGS+=(--output "$LAPTOP" --mode "$lm" --pos "${lx}x${ROW_H}")
fi

# Turn off everything we are not enabling.
for o in "${ALL[@]}"; do
    [[ -z "${ON[$o]}" ]] && ARGS+=(--output "$o" --off)
done

# Desired geometry set, normalized like current_geom.
WANT=$(for o in "${!ON[@]}"; do echo "$o=${ON[$o]}"; done | sort)

# --- Idempotency gate: only touch xrandr if the layout actually differs. ---
# --force bypasses the gate so a black-but-"active" external still gets retrained.
if [[ $FORCE -eq 0 && "$(current_geom)" == "$WANT" ]]; then
    ~/.local/bin/i3-assign-workspaces 2>/dev/null
    exit 0
fi

# Forced retrain: drop the external DP links, then bring them back below.
if [[ $FORCE -eq 1 ]]; then
    for o in "${EXT[@]}"; do xrandr --output "$o" --off 2>/dev/null; done
    sleep 1
fi

# Apply in a SINGLE xrandr call = a single event.
xrandr "${ARGS[@]}"
[[ -x ~/.fehbg ]] && ~/.fehbg

# Wait for i3 to see the new output set, THEN migrate/assign workspaces so
# orphans from removed outputs get renumbered into a surviving output's range.
wait_i3_outputs "${#ON[@]}"
~/.local/bin/i3-assign-workspaces 2>/dev/null
