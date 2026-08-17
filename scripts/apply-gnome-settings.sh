#!/usr/bin/env bash
# apply-gnome-settings.sh — Áp toàn bộ diện mạo GNOME Catppuccin Mocha Mauve (user-space)
# Wallpaper slideshow, GTK4/libadwaita, Burn-My-Windows profiles, dconf, Flatpak override.
set -uo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BG="$HOME/.local/share/backgrounds/rice"
THEME="catppuccin-mocha-mauve-standard+default"
log() { echo "[$(date +%H:%M:%S)] $*"; }

# 1. Wallpapers + slideshow XML (xoay vòng 30 phút/ảnh, chuyển cảnh 5s)
mkdir -p "$BG"
cp "$REPO_DIR"/wallpapers/*.{jpg,png} "$BG/" 2>/dev/null
{
  echo '<background>'
  echo '  <starttime><year>2026</year><month>1</month><day>1</day><hour>0</hour><minute>0</minute><second>0</second></starttime>'
  prev=""
  first=""
  for f in "$BG"/*.jpg "$BG"/*.png; do
    [ -f "$f" ] || continue
    [ -z "$first" ] && first="$f"
    if [ -n "$prev" ]; then
      echo "  <static><duration>1795.0</duration><file>$prev</file></static>"
      echo "  <transition><duration>5.0</duration><from>$prev</from><to>$f</to></transition>"
    fi
    prev="$f"
  done
  echo "  <static><duration>1795.0</duration><file>$prev</file></static>"
  echo "  <transition><duration>5.0</duration><from>$prev</from><to>$first</to></transition>"
  echo '</background>'
} > "$BG/slideshow.xml"
gsettings set org.gnome.desktop.background picture-uri "file://$BG/slideshow.xml"
gsettings set org.gnome.desktop.background picture-uri-dark "file://$BG/slideshow.xml"
gsettings set org.gnome.desktop.screensaver picture-uri "file://$BG/purpled-night.jpg"
log "Wallpaper slideshow OK ($(ls "$BG" | grep -cE 'jpg|png') ảnh)"

# 2. GTK4 / libadwaita — link assets của theme vào ~/.config/gtk-4.0
GTK4_SRC="$HOME/.themes/$THEME/gtk-4.0"
if [ -d "$GTK4_SRC" ]; then
  mkdir -p "$HOME/.config/gtk-4.0"
  ln -sfn "$GTK4_SRC/assets" "$HOME/.config/gtk-4.0/assets"
  ln -sf "$GTK4_SRC/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"
  ln -sf "$GTK4_SRC/gtk-dark.css" "$HOME/.config/gtk-4.0/gtk-dark.css"
  log "GTK4/libadwaita link OK"
fi

# 3. Burn-My-Windows — profile Aura Glow, áp cho CẢ mở lẫn đóng (animation-type=0)
BMW_DIR="$HOME/.config/burn-my-windows/profiles"
mkdir -p "$BMW_DIR"
cp "$REPO_DIR"/gnome/burn-my-windows/*.conf "$BMW_DIR/"
# v48 lưu active-profile bằng đường dẫn tuyệt đối
dconf write /org/gnome/shell/extensions/burn-my-windows/active-profile \
  "'$BMW_DIR/rice-aura-glow.conf'"
log "Burn-My-Windows Aura Glow OK"

# 4. dconf — toàn bộ theme/dock/panel/extension settings
dconf load / < "$REPO_DIR/gnome/dconf-rice.ini" && log "dconf load OK"

# 5. Flatpak apps dùng chung theme + icons + cursor
if command -v flatpak >/dev/null; then
  flatpak override --user \
    --filesystem="$HOME/.themes" \
    --filesystem="$HOME/.local/share/icons" \
    --filesystem=xdg-config/gtk-3.0 \
    --filesystem=xdg-config/gtk-4.0 \
    --env=GTK_THEME="$THEME" \
    --env=XCURSOR_THEME=catppuccin-mocha-mauve-cursors 2>/dev/null \
    && log "Flatpak override OK"
fi

# 6. GTK3 settings.ini (một số app đọc trực tiếp)
mkdir -p "$HOME/.config/gtk-3.0"
cat > "$HOME/.config/gtk-3.0/settings.ini" <<EOF
[Settings]
gtk-theme-name=$THEME
gtk-icon-theme-name=Tela-circle-purple-dark
gtk-cursor-theme-name=catppuccin-mocha-mauve-cursors
gtk-font-name=Inter 11
gtk-application-prefer-dark-theme=true
EOF
log "GTK3 settings.ini OK"

log "HOÀN TẤT — đăng xuất/đăng nhập lại để extensions mới (Open Bar, Blur, Burn, bo góc, User Theme) được nạp."
