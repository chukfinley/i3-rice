#!/bin/bash
# Get Spotify album for Conky

playerctl -p spotify metadata --format "{{ album }}" 2>/dev/null || echo ""
