# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture

This is an i3/Regolith-based Linux desktop configuration with per-monitor workspace management.

### Key Components

- **config/regolith3/** - Regolith-specific configs that extend i3
  - `Xresources` - Main config (terminal, keybindings, workspace names, look)
  - `i3/config.d/91_custom` - i3 config additions (workspace assignments, keybindings)
  - `flags/` - Regolith feature flags

- **config/qt5ct/, qt6ct/** - Qt theme configs for consistent dark theme on Qt apps (Flameshot context menu, etc.)

- **config/environment.d/qt-theme.conf** - Sets `QT_QPA_PLATFORMTHEME=qt5ct`

- **scripts/** - Helper scripts
  - `i3-workspace-per-monitor` - Maps Super+1-9 to monitor-specific workspaces
  - `dock-layout.sh` / `undock-layout.sh` - Multi-monitor configuration

### Per-Monitor Workspace System

The standard i3 workspace keys (Super+1-9) are disabled in Xresources (mapped to F13-F22).
Custom bindings in `91_custom` call the `i3-workspace-per-monitor` script which:

1. Gets the focused output from `i3-msg -t get_workspaces`
2. Maps output to workspace offset:
   - eDP-1 (laptop): offset 0 (workspaces 1-9)
   - DP-3-1: offset 10 (workspaces 11-19)
   - DP-3-2: offset 20 (workspaces 21-29)
3. Switches/moves to the calculated workspace

### Installation Flow

1. `install.sh` backs up existing `~/.config/*` to timestamped directory
2. Creates symlinks from `~/.config/*` to repo directories
3. Copies scripts to `~/.local/bin/` and makes them executable
4. Runs `regolith-look refresh` if available

## Commands

```bash
# Install (backs up existing configs, creates symlinks)
./install.sh

# Refresh after editing Xresources
regolith-look refresh

# Reload i3 config
i3-msg reload

# Restart i3 (preserves layout)
i3-msg restart

# Test workspace script manually
~/.local/bin/i3-workspace-per-monitor switch 1
~/.local/bin/i3-workspace-per-monitor move 3
```

## Config Editing

When editing configs:

- **Xresources changes**: Run `regolith-look refresh` to apply
- **91_custom changes**: Run `i3-msg reload` to apply
- **Script changes**: Changes take effect immediately (scripts run fresh each time)

## Paths Used

- Configs symlinked to: `~/.config/{regolith3,qt5ct,qt6ct,alacritty,...}`
- Scripts installed to: `~/.local/bin/`
- Wallpapers expected in: `~/Pictures/wal/`
- Backup location: `~/.config-backup-YYYYMMDD-HHMMSS/`
