#!/usr/bin/env bash
# install-cli-theme.sh — Theme Catppuccin Mocha cho terminal & CLI stack (user-space)
# Ghostty, p10k, fzf/eza (qua zshrc), bat, btop, fastfetch, tmux.
set -uo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
log() { echo "[$(date +%H:%M:%S)] $*"; }

# 1. Ghostty — đổi theme sang catppuccin-mocha (giữ nguyên phần còn lại)
GHOSTTY="$HOME/.config/ghostty/config"
if [ -f "$GHOSTTY" ]; then
  if grep -qE '^theme = ' "$GHOSTTY"; then
    sed -i 's/^theme = .*/theme = catppuccin-mocha/' "$GHOSTTY"
  else
    echo "theme = catppuccin-mocha" >> "$GHOSTTY"
  fi
  mkdir -p "$REPO_DIR/configs/ghostty" && cp "$GHOSTTY" "$REPO_DIR/configs/ghostty/config"
  log "Ghostty → catppuccin-mocha"
fi

# 2. p10k overrides — copy file + append source vào ~/.p10k.zsh (idempotent)
mkdir -p "$HOME/.config/zsh"
cp "$REPO_DIR/configs/zsh/p10k-catppuccin-overrides.zsh" "$HOME/.config/zsh/"
if [ -f "$HOME/.p10k.zsh" ] && ! grep -q "p10k-catppuccin-overrides" "$HOME/.p10k.zsh"; then
  printf '\n# Catppuccin Mocha overrides (ubuntu-catppuccin-rice)\nsource "$HOME/.config/zsh/p10k-catppuccin-overrides.zsh"\n' >> "$HOME/.p10k.zsh"
  log "p10k overrides appended"
else
  log "p10k overrides đã có / không có ~/.p10k.zsh"
fi

# 3. fzf/eza/grep colors — source từ ~/.zshrc (idempotent)
cp "$REPO_DIR/configs/zsh/catppuccin-cli.zsh" "$HOME/.config/zsh/"
if ! grep -q "catppuccin-cli.zsh" "$HOME/.zshrc"; then
  printf '\n# Catppuccin Mocha CLI colors (ubuntu-catppuccin-rice)\n[[ -f "$HOME/.config/zsh/catppuccin-cli.zsh" ]] && source "$HOME/.config/zsh/catppuccin-cli.zsh"\n' >> "$HOME/.zshrc"
  log "zshrc: source catppuccin-cli.zsh appended"
fi

# 4. bat
if command -v bat >/dev/null; then
  BAT_DIR="$(bat --config-dir)"
  mkdir -p "$BAT_DIR/themes"
  cp "$REPO_DIR/configs/bat/Catppuccin Mocha.tmTheme" "$BAT_DIR/themes/"
  bat cache --build >/dev/null
  BAT_CFG="$(bat --config-file)"
  mkdir -p "$(dirname "$BAT_CFG")"; touch "$BAT_CFG"
  grep -q 'Catppuccin Mocha' "$BAT_CFG" || echo '--theme="Catppuccin Mocha"' >> "$BAT_CFG"
  log "bat OK"
fi

# 5. btop
mkdir -p "$HOME/.config/btop/themes"
cp "$REPO_DIR/configs/btop/catppuccin_mocha.theme" "$HOME/.config/btop/themes/"
BTOP_CFG="$HOME/.config/btop/btop.conf"
if [ -f "$BTOP_CFG" ]; then
  sed -i 's|^color_theme = .*|color_theme = "catppuccin_mocha"|' "$BTOP_CFG"
  grep -q '^color_theme' "$BTOP_CFG" || echo 'color_theme = "catppuccin_mocha"' >> "$BTOP_CFG"
else
  printf 'color_theme = "catppuccin_mocha"\ntheme_background = False\n' > "$BTOP_CFG"
fi
log "btop OK"

# 6. fastfetch
mkdir -p "$HOME/.config/fastfetch"
cp "$REPO_DIR/configs/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
log "fastfetch OK"

# 7. tmux (chưa có config trước đó — backup rollback sẽ xoá nếu cần)
mkdir -p "$HOME/.config/tmux"
cp "$REPO_DIR/configs/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf"
log "tmux OK"

log "HOÀN TẤT install-cli-theme — mở terminal mới để thấy thay đổi."
