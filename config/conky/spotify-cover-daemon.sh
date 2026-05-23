#!/bin/bash
# Spotify cover updater for Conky

CACHE_FILE="/tmp/conky-spotify-cover.jpg"
mkdir -p "$HOME/.cache/conky-spotify"

get_current_track_id() {
    playerctl -p spotify metadata --format "{{mpris:trackid}}" 2>/dev/null || echo ""
}

LAST_TRACK_ID=""

while true; do
    STATUS=$(playerctl -p spotify status 2>/dev/null || echo "Stopped")
    
    if [ "$STATUS" = "Playing" ] || [ "$STATUS" = "Paused" ]; then
        TRACK_ID=$(get_current_track_id)
        ART_URL=$(playerctl -p spotify metadata mpris:artUrl 2>/dev/null)
        
        # Update if track changed or first run
        if [ -n "$ART_URL" ] && ([ "$TRACK_ID" != "$LAST_TRACK_ID" ] || [ ! -f "$CACHE_FILE" ]); then
            curl -s -L --max-time 5 -o "$CACHE_FILE.tmp" "$ART_URL" 2>/dev/null
            if [ -s "$CACHE_FILE.tmp" ]; then
                mv "$CACHE_FILE.tmp" "$CACHE_FILE"
                LAST_TRACK_ID="$TRACK_ID"
            fi
        fi
    else
        # No music - remove cover so default shows
        if [ -f "$CACHE_FILE" ]; then
            rm -f "$CACHE_FILE"
        fi
        LAST_TRACK_ID=""
    fi
    
    sleep 2
done
