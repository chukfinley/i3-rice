# i3-rice

Regolith/i3 dotfiles with per-monitor workspaces, Qt theming, and multi-monitor support.

## Features

- **Per-monitor workspaces**: Super+1-9 switches workspaces relative to the focused monitor
- **Qt theming**: Consistent dark theme for Qt5/Qt6 apps (Flameshot, etc.)
- **Multi-monitor support**: Dock/undock scripts for laptop + external monitors
- **Alacritty terminal**: Dark theme with Comic Code font
- **Picom compositor**: Shadows and transparency for Alacritty

## Quick Install

```bash
git clone https://github.com/chukfinley/i3-rice.git
cd i3-rice
./install.sh
```

## Monitor Layout

| Monitor | Output | Workspaces |
|---------|--------|------------|
| Laptop | eDP-1 | 1-9 |
| External 1 | DP-3-1 | 11-19 |
| External 2 | DP-3-2 | 21-29 |

## Keybindings

| Key | Action |
|-----|--------|
| Super+1-9 | Switch to workspace on current monitor |
| Super+Shift+1-9 | Move window to workspace on current monitor |
| Super+Q | Close window |
| Super+W | Lock screen |
| Super+Enter | Terminal (Alacritty) |
| Super+= | Resize mode |
| Super+R | Voice input (Fluistern) |

## Structure

```
i3-rice/
├── install.sh              # Installation script
├── picom.conf              # Compositor config
├── config/
│   ├── regolith3/          # Regolith/i3 configs
│   │   ├── Xresources      # Regolith resources
│   │   ├── i3/config.d/    # i3 config partials
│   │   └── flags/          # Regolith feature flags
│   ├── qt5ct/              # Qt5 theme config
│   ├── qt6ct/              # Qt6 theme config
│   ├── alacritty/          # Terminal config
│   ├── environment.d/      # Environment variables
│   ├── autostart/          # Autostart entries
│   ├── mpv/                # Video player config
│   ├── yt-dlp/             # Video downloader config
│   └── xdg-desktop-portal/ # Portal config
├── scripts/
│   ├── i3-workspace-per-monitor  # Workspace switching script
│   ├── dock-layout.sh            # Multi-monitor setup
│   └── undock-layout.sh          # Single monitor fallback
└── wallpaper/              # Wallpaper directory
```

## Dependencies

Installed by `install.sh`:
- i3-wm
- alacritty
- qt5ct, qt6ct
- jq
- dunst
- picom
- feh
- xdotool
- rofi

## Related

- [dwm-rice](https://github.com/chukfinley/dwm-rice) - dwm-based setup with live wallpaper theming
