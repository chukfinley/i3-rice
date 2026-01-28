# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture

This is an i3/Regolith-based Linux desktop configuration with per-monitor workspace management.

### Key Components

- **config/regolith3/** - Regolith-specific configs that extend i3
  - `Xresources` - Main config (terminal, keybindings, workspace names, look)
  - `i3/config.d/91_custom` - i3 config additions (workspace assignments, keybindings)
  - `flags/` - Regolith feature flags

- **config/qt5ct/, qt6ct/** - Qt theme configs for consistent dark theme on Qt apps (Flameshot, etc.)
  - Use `standard_dialogs=default` (not gtk3) to avoid text visibility issues in Flameshot menus

- **config/environment.d/qt-theme.conf** - Sets `QT_QPA_PLATFORMTHEME=qt5ct`

- **config/autostart/picom.desktop** - Autostart for picom compositor

- **config/applications/** - Custom .desktop files for launchers (rofi, vicinae)
  - `caja.desktop` - Caja without `OnlyShowIn=MATE` (system version is hidden in non-MATE desktops)

- **scripts/** - Helper scripts
  - `i3-workspace-per-monitor` - Maps Super+1-9 to monitor-specific workspaces
  - `dock-layout.sh` / `undock-layout.sh` - Multi-monitor configuration

### PICOM Configuration

PICOM uses the config at `~/.config/dwm/picom.conf` (NOT in this repo).

**Important**: After `regolith-look refresh`, picom keeps running but stops working. Always:
```bash
pkill -9 picom; sleep 0.5; picom -b --config ~/.config/dwm/picom.conf
```

The monitors have different refresh rates - do NOT set `refresh-rate` in picom.conf (let it auto-detect).

### GTK Theme

Regolith sets GTK theme via gsettings (Nordic theme), NOT via config files. Do NOT create ~/.config/gtk-3.0 or gtk-4.0 directories - they will conflict with Regolith's settings.

### Per-Monitor Workspace System

The standard i3 workspace keys (Super+1-9) are disabled in Xresources (mapped to F13-F22).
Custom bindings in `91_custom` call the `i3-workspace-per-monitor` script which:

1. Gets the focused output from `i3-msg -t get_workspaces`
2. Maps output to workspace offset:
   - eDP-1 (laptop): offset 0 (workspaces 1-9)
   - DP-3-1: offset 10 (workspaces 11-19)
   - DP-3-2: offset 20 (workspaces 21-29)
3. Switches/moves to the calculated workspace

### Monitor Layout (Docked)

- eDP-1 (laptop): bottom-left, 1920x1080
- DP-3-1: top-left, 2560x1080
- DP-3-2: top-right, 2560x1080

Run `dock-layout.sh` to apply this layout.

### Installation Flow

1. `install.sh` backs up existing `~/.config/*` to timestamped directory
2. Creates symlinks from `~/.config/*` to repo directories
3. Copies scripts to `~/.local/bin/` and makes them executable
4. Runs `regolith-look refresh` if available

## Commands

```bash
# Install (backs up existing configs, creates symlinks)
./install.sh

# Refresh after editing Xresources (then restart picom!)
regolith-look refresh
pkill -9 picom; picom -b --config ~/.config/dwm/picom.conf

# Reload i3 config
i3-msg reload

# Restart i3 (preserves layout) - also needs picom restart
i3-msg restart
pkill -9 picom; picom -b --config ~/.config/dwm/picom.conf

# Apply Xresources changes
xrdb -merge ~/.config/regolith3/Xresources && i3-msg restart

# Test workspace script manually
~/.local/bin/i3-workspace-per-monitor switch 1
~/.local/bin/i3-workspace-per-monitor move 3

# Apply monitor layout
~/.local/bin/dock-layout.sh
```

## Custom Keybindings

| Keybinding | Action |
|------------|--------|
| Super+Shift+Space | Toggle floating/tiling mode |
| Super+1-9 | Switch to workspace on current monitor |
| Super+Shift+1-9 | Move window to workspace on current monitor |
| Super+Q | Close window |
| Super+W | Lock screen |
| Super+R | Fluistern (voice input) |
| Super+Shift+D | Vicinae |
| Super+= | Resize mode |
| Super+Enter | Terminal (Alacritty) |

## Config Editing

When editing configs:

- **Xresources changes**: Run `xrdb -merge ~/.config/regolith3/Xresources && i3-msg restart`, then restart picom
- **91_custom changes**: Run `i3-msg reload` to apply
- **Script changes**: Changes take effect immediately (scripts run fresh each time)

## Paths Used

- Configs symlinked to: `~/.config/{regolith3,qt5ct,qt6ct,alacritty,...}`
- Scripts installed to: `~/.local/bin/`
- Wallpapers: `~/pic/wal/`
- PICOM config: `~/.config/dwm/picom.conf`
- Backup location: `~/.config-backup-YYYYMMDD-HHMMSS/`

## i3xrocks Bar Blocks

Installed blocks (shown in bar):
- i3xrocks-microphone
- i3xrocks-tailscale

Blocks auto-load from `/usr/share/i3xrocks/conf.d/`. After installing new blocks, run `regolith-look refresh` (and restart picom).
