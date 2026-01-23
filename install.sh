#!/bin/bash
# Install script for i3-rice on Regolith / Ubuntu
# This sets up i3/Regolith with per-monitor workspaces and Qt theming

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"

echo "========================================"
echo "  i3-rice installer for Regolith"
echo "========================================"
echo ""

# Check for root
if [[ $EUID -eq 0 ]]; then
    echo "Do not run this script as root. Run as your normal user."
    exit 1
fi

# Install dependencies
echo "[1/5] Installing dependencies..."
sudo apt update
sudo apt install -y \
    i3-wm \
    alacritty \
    qt5ct \
    qt6ct \
    jq \
    dunst \
    picom \
    feh \
    xdotool \
    rofi

# Optional: Install regolith-desktop if not present
if ! command -v regolith-look &>/dev/null; then
    echo "Note: regolith-look not found. Install regolith-desktop for full functionality."
fi

echo ""
echo "[2/5] Backing up existing configs..."
mkdir -p "$BACKUP_DIR"

# Backup existing configs
for dir in regolith3 qt5ct qt6ct alacritty environment.d autostart mpv yt-dlp xdg-desktop-portal; do
    if [[ -e "$HOME/.config/$dir" ]]; then
        echo "  Backing up ~/.config/$dir"
        cp -r "$HOME/.config/$dir" "$BACKUP_DIR/"
    fi
done

if [[ -e "$HOME/.config/picom.conf" ]]; then
    cp "$HOME/.config/picom.conf" "$BACKUP_DIR/"
fi

echo "  Backup saved to: $BACKUP_DIR"

echo ""
echo "[3/5] Creating symlinks..."

# Create config directory structure
mkdir -p "$HOME/.config"

# Symlink config directories
for dir in regolith3 qt5ct qt6ct alacritty environment.d autostart mpv yt-dlp xdg-desktop-portal; do
    src="$SCRIPT_DIR/config/$dir"
    dst="$HOME/.config/$dir"

    if [[ -d "$src" ]]; then
        # Remove existing (backup already made)
        rm -rf "$dst"
        ln -sf "$src" "$dst"
        echo "  Linked: ~/.config/$dir"
    fi
done

# Symlink picom.conf
if [[ -f "$SCRIPT_DIR/picom.conf" ]]; then
    rm -f "$HOME/.config/picom.conf"
    ln -sf "$SCRIPT_DIR/picom.conf" "$HOME/.config/picom.conf"
    echo "  Linked: ~/.config/picom.conf"
fi

echo ""
echo "[4/5] Installing scripts..."
mkdir -p "$HOME/.local/bin"

for script in "$SCRIPT_DIR/scripts/"*; do
    if [[ -f "$script" ]]; then
        name=$(basename "$script")
        cp "$script" "$HOME/.local/bin/$name"
        chmod +x "$HOME/.local/bin/$name"
        echo "  Installed: ~/.local/bin/$name"
    fi
done

# Update scripts with correct home path
sed -i "s|/home/user|$HOME|g" "$HOME/.local/bin/"* 2>/dev/null || true

echo ""
echo "[5/5] Post-install setup..."

# Refresh regolith look if available
if command -v regolith-look &>/dev/null; then
    echo "  Refreshing regolith look..."
    regolith-look refresh 2>/dev/null || true
fi

# Create wallpaper directory
mkdir -p "$HOME/Pictures/wal"

echo ""
echo "========================================"
echo "  Installation complete!"
echo "========================================"
echo ""
echo "Keybindings:"
echo "  Super+1-9       - Switch to workspace on current monitor"
echo "  Super+Shift+1-9 - Move window to workspace on current monitor"
echo "  Super+Q         - Close window"
echo "  Super+W         - Lock screen"
echo "  Super+R         - Voice input (Fluistern)"
echo "  Super+=         - Resize mode"
echo "  Super+Enter     - Terminal (Alacritty)"
echo ""
echo "Monitor Layout:"
echo "  Laptop (eDP-1)     - Workspaces 1-9"
echo "  External 1 (DP-3-1) - Workspaces 11-19"
echo "  External 2 (DP-3-2) - Workspaces 21-29"
echo ""
echo "Scripts installed to ~/.local/bin/:"
echo "  i3-workspace-per-monitor - Per-monitor workspace switching"
echo "  dock-layout.sh           - Configure monitors when docking"
echo "  undock-layout.sh         - Reset to laptop screen when undocking"
echo ""
echo "Next steps:"
echo "1. Add wallpapers to ~/Pictures/wal/"
echo "2. Log out and log back in (or run: regolith-look refresh)"
echo "3. Test Super+1-9 workspace switching"
echo ""
