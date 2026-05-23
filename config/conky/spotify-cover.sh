#!/bin/bash
# Spotify Cover Art Fetcher for Conky
# Requires: playerctl, curl, imagemagick (optional, for resizing)

CACHE_DIR="$HOME/.cache/conky-spotify"
mkdir -p "$CACHE_DIR"

# Get current track info
STATUS=$(playerctl -p spotify status 2>/dev/null || echo "Stopped")
if [ "$STATUS" != "Playing" ] && [ "$STATUS" != "Paused" ]; then
    echo "No music playing"
    exit 0
fi

# Get album art URL
ART_URL=$(playerctl -p spotify metadata mpris:artUrl 2>/dev/null | sed 's/file:\/\///')
if [ -z "$ART_URL" ]; then
    exit 0
fi

# Create a hash of the URL for caching
URL_HASH=$(echo "$ART_URL" | md5sum | cut -d' ' -f1)
COVER_FILE="$CACHE_DIR/$URL_HASH.jpg"
COVER_RESIZED="$CACHE_DIR/$URL_HASH-200.jpg"

# Download if not cached
if [ ! -f "$COVER_FILE" ]; then
    curl -s -L -o "$COVER_FILE" "$ART_URL" 2>/dev/null
fi

# Resize for conky (200x200 is good for conky)
if [ -f "$COVER_FILE" ] && [ ! -f "$COVER_RESIZED" ]; then
    if command -v convert &> /dev/null; then
        convert "$COVER_FILE" -resize 200x200 "$COVER_RESIZED" 2>/dev/null
    else
        cp "$COVER_FILE" "$COVER_RESIZED"
    fi
fi

# Output the path for conky
if [ -f "$COVER_RESIZED" ]; then
    echo "$COVER_RESIZED"
else
    echo "$COVER_FILE"
fi
