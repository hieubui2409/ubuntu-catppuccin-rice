#!/usr/bin/env bash
# rollback.sh — Khôi phục TOÀN BỘ trạng thái trước khi rice từ backups/<ngày>/
# Cách dùng:
#   ./scripts/rollback.sh                 # rollback phần user-space (dconf, configs)
#   sudo ./scripts/rollback.sh --system   # rollback thêm GRUB / Plymouth / GDM
# Backup mới nhất được chọn tự động; chỉ định thư mục:  ./scripts/rollback.sh 20260811
set -uo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SYSTEM=0
BK_NAME=""
for arg in "$@"; do
  case "$arg" in
    --system) SYSTEM=1 ;;
    *) BK_NAME="$arg" ;;
  esac
done

if [ -n "$BK_NAME" ]; then
  BK="$REPO_DIR/backups/$BK_NAME"
else
  BK=$(ls -d "$REPO_DIR"/backups/*/ 2>/dev/null | sort | tail -1)
fi
[ -d "$BK" ] || { echo "Không tìm thấy backup trong $REPO_DIR/backups/"; exit 1; }
echo "== Rollback từ: $BK =="

# Khi chạy sudo, các lệnh user-space phải chạy dưới user gốc
REAL_USER="${SUDO_USER:-$USER}"
run_user() { if [ "$(id -u)" -eq 0 ]; then sudo -u "$REAL_USER" env DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$REAL_USER")/bus" "$@"; else "$@"; fi; }

# 1. dconf (toàn bộ GNOME settings, extensions config, dock, theme...)
if [ -f "$BK/dconf/dconf-full.ini" ]; then
  run_user dconf load / < "$BK/dconf/dconf-full.ini" && echo "✓ dconf khôi phục"
fi

# 2. Configs cá nhân
declare -A FILES=(
  ["configs/ghostty-config"]="$HOME/.config/ghostty/config"
  ["configs/starship.toml"]="$HOME/.config/starship.toml"
  ["configs/zshrc"]="$HOME/.zshrc"
  ["configs/p10k.zsh"]="$HOME/.p10k.zsh"
  ["configs/vscode-settings.json"]="$HOME/.config/Code/User/settings.json"
)
for src in "${!FILES[@]}"; do
  if [ -f "$BK/$src" ]; then
    cp "$BK/$src" "${FILES[$src]}" && echo "✓ ${FILES[$src]}"
  fi
done

# 3. Gỡ file cấu hình do rice tạo mới (không có trong backup nghĩa là trước đó chưa tồn tại)
for f in "$HOME/.config/fastfetch/config.jsonc" "$HOME/.config/btop/themes/catppuccin_mocha.theme" \
         "$HOME/.config/tmux/tmux.conf" "$HOME/.zsh-catppuccin-rice.zsh" \
         "$HOME/.config/kdeglobals" \
         "$HOME/.local/share/color-schemes/CatppuccinMochaMauve.colors" \
         "$HOME/.local/share/org.kde.syntax-highlighting/themes/catppuccin-mocha.theme"; do
  [ -f "$BK/configs/$(basename "$f")" ] || rm -f "$f" 2>/dev/null
done

# Kate — trả về theme mặc định (katerc tồn tại từ trước nên chỉ reset các key rice đã sửa)
if command -v kwriteconfig5 >/dev/null; then
  kwriteconfig5 --file katerc --group "KTextEditor Renderer" --key "Color Theme" "Breeze Light"
  kwriteconfig5 --file katerc --group "KTextEditor Renderer" --key "Auto Color Theme Selection" "true"
  kwriteconfig5 --file katerc --group "KTextEditor Renderer" --key "Font" "monospace,11,-1,2,50,0,0,0,0,0"
  echo "✓ Kate khôi phục"
fi

if [ "$SYSTEM" -eq 1 ]; then
  [ "$(id -u)" -eq 0 ] || { echo "--system cần sudo"; exit 1; }
  echo "== Rollback system =="
  # 4. GRUB — khôi phục config gốc, gỡ theme
  if [ -f /etc/default/grub.rice-bak ]; then
    cp /etc/default/grub.rice-bak /etc/default/grub
  elif [ -f "$BK/system/grub-default" ]; then
    cp "$BK/system/grub-default" /etc/default/grub
  fi
  rm -rf /usr/share/grub/themes/catppuccin-mocha-grub-theme 2>/dev/null
  update-grub && echo "✓ GRUB khôi phục"
  # 5. Plymouth — gỡ alternative rice, hệ thống tự quay về mặc định (bgrt)
  update-alternatives --remove default.plymouth \
    /usr/share/plymouth/themes/catppuccin-mocha/catppuccin-mocha.plymouth 2>/dev/null
  rm -rf /usr/share/plymouth/themes/catppuccin-mocha 2>/dev/null
  update-initramfs -u && echo "✓ Plymouth khôi phục"
  # 6. GDM — gỡ alternative rice, quay về Yaru gốc (file gốc chưa từng bị sửa)
  update-alternatives --remove gdm-theme.gresource \
    /usr/local/share/gnome-shell/theme/rice-catppuccin/gnome-shell-theme.gresource 2>/dev/null
  rm -rf /usr/local/share/gnome-shell/theme/rice-catppuccin 2>/dev/null
  echo "✓ GDM khôi phục (Yaru)"
fi

echo "== XONG. Đăng xuất/đăng nhập lại để mọi thứ trở về như cũ. =="
echo "   (Theme/icon đã tải vẫn nằm trong ~/.themes, ~/.local/share/icons — vô hại, xoá tay nếu muốn.)"
