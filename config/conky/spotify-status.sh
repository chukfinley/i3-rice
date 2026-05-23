#!/bin/bash
# Check if Spotify is playing

STATUS=$(playerctl -p spotify status 2>/dev/null || echo "Stopped")
if [ "$STATUS" = "Playing" ] || [ "$STATUS" = "Paused" ]; then
    echo "1"
else
    echo "0"
fi
