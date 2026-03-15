# i3-rice

Regolith/i3 dotfiles with an optional AwesomeWM profile, Qt theming, and multi-monitor support.

## Features

- **Per-monitor workspaces**: Super+1-9 switches workspaces relative to the focused monitor
- **AwesomeWM profile**: i3-like shortcuts plus clickable top-bar dropdown menus
- **Qt theming**: Consistent dark theme for Qt5/Qt6 apps (Flameshot, etc.)
- **Multi-monitor support**: Dock/undock scripts for laptop + external monitors
- **Alacritty terminal**: Dark theme with Comic Code font
- **Picom compositor**: Shadows and transparency for Alacritty
- **Flameshot autostart**: Screenshot tool starts automatically in tray

## Quick Install

```bash
git clone https://github.com/chukfinley/i3-rice.git
cd i3-rice
./install.sh
```

## Window Manager Choice

- **i3/Regolith** remains available with the existing setup.
- **AwesomeWM** config is shipped at `config/awesome/rc.lua`.
- Test Awesome from an i3 session with:

```bash
awesome --replace
```

If you see `another window manager is already running`, use `awesome --replace` (or select Awesome on the login screen).

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
│   │   ├── i3xrocks/conf.d/ # Custom bar blocks
│   │   └── flags/           # Regolith feature flags
│   ├── awesome/            # AwesomeWM config
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
- awesome
- alacritty
- qt5ct, qt6ct
- jq
- dunst
- picom
- flameshot
- feh
- xdotool
- rofi

## Related

- [dwm-rice](https://github.com/chukfinley/dwm-rice) - dwm-based setup with live wallpaper theming
