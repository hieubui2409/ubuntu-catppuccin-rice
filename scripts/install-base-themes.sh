#!/usr/bin/env bash
# install-base-themes.sh — Cài base themes Catppuccin Mocha Mauve (user-space, không cần sudo)
# GTK theme, Tela-circle purple icons, Catppuccin cursors, font Inter, wallpapers.
set -uo pipefail

WORK="${TMPDIR:-/tmp}/rice-downloads"
THEMES="$HOME/.themes"
ICONS="$HOME/.local/share/icons"
FONTS="$HOME/.local/share/fonts"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WALLS="$REPO_DIR/wallpapers"
mkdir -p "$WORK" "$THEMES" "$ICONS" "$FONTS" "$WALLS"

log() { echo "[$(date +%H:%M:%S)] $*"; }

# 1. GTK theme — catppuccin/gtk (bản build sẵn mocha-mauve)
if [ ! -d "$THEMES/catppuccin-mocha-mauve-standard+default" ]; then
  log "Tải GTK theme catppuccin-mocha-mauve..."
  curl -fsSL -o "$WORK/gtk-mocha-mauve.zip" \
    "https://github.com/catppuccin/gtk/releases/download/v1.0.3/catppuccin-mocha-mauve-standard+default.zip" \
    && unzip -oq "$WORK/gtk-mocha-mauve.zip" -d "$THEMES/" \
    && log "GTK theme OK" || log "GTK theme LỖI"
else
  log "GTK theme đã có"
fi

# 2. Tela-circle icons (purple)
if [ ! -d "$ICONS/Tela-circle-purple-dark" ]; then
  log "Cài Tela-circle purple..."
  rm -rf "$WORK/Tela-circle-icon-theme"
  git clone --depth 1 https://github.com/vinceliuice/Tela-circle-icon-theme.git "$WORK/Tela-circle-icon-theme" \
    && "$WORK/Tela-circle-icon-theme/install.sh" -d "$ICONS" purple >/dev/null \
    && log "Tela-circle OK" || log "Tela-circle LỖI"
else
  log "Tela-circle đã có"
fi

# 3. Catppuccin cursors (mocha mauve)
if [ ! -d "$ICONS/catppuccin-mocha-mauve-cursors" ]; then
  log "Tải Catppuccin cursors..."
  curl -fsSL -o "$WORK/cursors.zip" \
    "https://github.com/catppuccin/cursors/releases/download/v2.0.0/catppuccin-mocha-mauve-cursors.zip" \
    && unzip -oq "$WORK/cursors.zip" -d "$ICONS/" \
    && log "Cursors OK" || log "Cursors LỖI"
else
  log "Cursors đã có"
fi

# 4. Font Inter (user-space)
if ! fc-list | grep -qi "Inter:style=Regular"; then
  log "Tải font Inter..."
  curl -fsSL -o "$WORK/inter.zip" \
    "https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip" \
    && unzip -oq "$WORK/inter.zip" -d "$WORK/inter" \
    && mkdir -p "$FONTS/inter" \
    && cp "$WORK/inter/extras/ttf/"Inter*.ttf "$FONTS/inter/" 2>/dev/null \
    ; cp "$WORK/inter/InterVariable"*.ttf "$FONTS/inter/" 2>/dev/null \
    ; fc-cache -f "$FONTS/inter" >/dev/null 2>&1 \
    && log "Inter OK" || log "Inter LỖI"
else
  log "Inter đã có"
fi

# 5. Wallpapers Catppuccin Mocha (chọn lọc từ orangci/walls-catppuccin-mocha)
if [ ! -f "$WALLS/purpled-night.png" ] && [ ! -f "$WALLS/purpled-night.jpg" ]; then
  log "Tải wallpapers..."
  rm -rf "$WORK/walls"
  git clone --depth 1 https://github.com/orangci/walls-catppuccin-mocha.git "$WORK/walls" >/dev/null 2>&1
  for name in galaxy-waves purple-horizon purpled-night lonely-fish sunset shaded-landscape clouds; do
    f=$(find "$WORK/walls" -maxdepth 1 -iname "${name}.*" | head -1)
    [ -n "$f" ] && cp "$f" "$WALLS/" && log "  + $(basename "$f")"
  done
else
  log "Wallpapers đã có"
fi

# 6. btop + fastfetch qua Homebrew (đã có linuxbrew)
if command -v brew >/dev/null; then
  command -v btop >/dev/null || { log "Cài btop..."; brew install btop >/dev/null 2>&1 && log "btop OK"; }
  command -v fastfetch >/dev/null || { log "Cài fastfetch..."; brew install fastfetch >/dev/null 2>&1 && log "fastfetch OK"; }
fi

log "HOÀN TẤT install-base-themes"
