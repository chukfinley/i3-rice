#!/bin/bash
# Get Spotify track info for Conky

playerctl -p spotify metadata --format "{{ artist }} - {{ title }}" 2>/dev/null || echo ""
