#!/usr/bin/env bash
# install-system.sh — Phần system-level của rice: GRUB + Plymouth + GDM background.
# CHẠY:  sudo ./scripts/install-system.sh
# An toàn: không ghi đè file gốc nào — GRUB backup /etc/default/grub thành .rice-bak,
# Plymouth/GDM đăng ký qua update-alternatives (gỡ = rollback.sh --system).
set -uo pipefail

[ "$(id -u)" -eq 0 ] || { echo "Cần sudo: sudo $0"; exit 1; }
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
log() { echo "[$(date +%H:%M:%S)] $*"; }
FAIL=0

# ---------- 1. GRUB ----------
if [ -f "$REPO_DIR/assets/catppuccin-grub.tar.gz" ]; then
  log "GRUB: cài theme catppuccin-mocha..."
  tar xzf "$REPO_DIR/assets/catppuccin-grub.tar.gz" -C "$WORK"
  SRC=$(find "$WORK" -maxdepth 3 -type d -name "catppuccin-mocha-grub-theme" | head -1)
  if [ -n "$SRC" ] && [ -f "$SRC/theme.txt" ]; then
    mkdir -p /usr/share/grub/themes
    rm -rf /usr/share/grub/themes/catppuccin-mocha-grub-theme
    cp -r "$SRC" /usr/share/grub/themes/
    [ -f /etc/default/grub.rice-bak ] || cp /etc/default/grub /etc/default/grub.rice-bak
    # đặt/ thay GRUB_THEME; bảo đảm gfxmode
    if grep -q '^GRUB_THEME=' /etc/default/grub; then
      sed -i 's|^GRUB_THEME=.*|GRUB_THEME="/usr/share/grub/themes/catppuccin-mocha-grub-theme/theme.txt"|' /etc/default/grub
    else
      echo 'GRUB_THEME="/usr/share/grub/themes/catppuccin-mocha-grub-theme/theme.txt"' >> /etc/default/grub
    fi
    grep -q '^GRUB_GFXMODE=' /etc/default/grub || echo 'GRUB_GFXMODE=auto' >> /etc/default/grub
    # GRUB_TERMINAL=console sẽ vô hiệu theme — comment nếu đang bật
    sed -i 's|^GRUB_TERMINAL=console|#GRUB_TERMINAL=console|' /etc/default/grub
    if update-grub 2>&1 | tail -2; then log "GRUB OK"; else log "GRUB LỖI update-grub"; FAIL=1; fi
  else
    log "GRUB: không tìm thấy theme trong tarball"; FAIL=1
  fi
fi

# ---------- 2. Plymouth ----------
if [ -f "$REPO_DIR/assets/catppuccin-plymouth.tar.gz" ]; then
  log "Plymouth: cài theme catppuccin-mocha..."
  tar xzf "$REPO_DIR/assets/catppuccin-plymouth.tar.gz" -C "$WORK"
  PSRC=$(find "$WORK" -maxdepth 3 -type d -name "catppuccin-mocha" -path "*themes*" | head -1)
  if [ -n "$PSRC" ] && [ -f "$PSRC/catppuccin-mocha.plymouth" ]; then
    rm -rf /usr/share/plymouth/themes/catppuccin-mocha
    cp -r "$PSRC" /usr/share/plymouth/themes/
    update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth \
      /usr/share/plymouth/themes/catppuccin-mocha/catppuccin-mocha.plymouth 200
    update-alternatives --set default.plymouth \
      /usr/share/plymouth/themes/catppuccin-mocha/catppuccin-mocha.plymouth
    if update-initramfs -u >/dev/null 2>&1; then log "Plymouth OK"; else log "Plymouth LỖI update-initramfs"; FAIL=1; fi
  else
    log "Plymouth: không tìm thấy theme trong tarball"; FAIL=1
  fi
fi

# ---------- 3. GDM background (an toàn qua update-alternatives, không sửa file Yaru) ----------
log "GDM: build gresource với nền Catppuccin..."
BGIMG="$REPO_DIR/wallpapers/purpled-night.jpg"
SRC_GRES="/usr/share/gnome-shell/theme/Yaru/gnome-shell-theme.gresource"
if [ -f "$BGIMG" ] && [ -f "$SRC_GRES" ]; then
  GDIR="$WORK/gdm-theme"
  PREFIX="/org/gnome/shell/theme"
  mkdir -p "$GDIR$PREFIX"
  # trích toàn bộ resource gốc
  while IFS= read -r r; do
    mkdir -p "$GDIR$(dirname "$r")"
    gresource extract "$SRC_GRES" "$r" > "$GDIR$r"
  done < <(gresource list "$SRC_GRES")
  # thêm ảnh nền + override CSS cho màn hình login/lock
  cp "$BGIMG" "$GDIR$PREFIX/rice-background.jpg"
  for css in "$GDIR$PREFIX/gnome-shell.css" "$GDIR$PREFIX/gnome-shell-dark.css" "$GDIR$PREFIX/gnome-shell-light.css"; do
    [ -f "$css" ] || continue
    cat >> "$css" <<'EOF'

/* ubuntu-catppuccin-rice: nền GDM */
#lockDialogGroup {
  background: #1e1e2e url("resource:///org/gnome/shell/theme/rice-background.jpg");
  background-size: cover;
  background-position: center;
}
EOF
  done
  # build gresource mới
  XML="$GDIR/rice.gresource.xml"
  {
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<gresources><gresource prefix="/">'
    (cd "$GDIR" && find . -type f ! -name "*.xml" | sed 's|^\./||' | while read -r f; do
      echo "    <file>$f</file>"
    done)
    echo '</gresource></gresources>'
  } > "$XML"
  if (cd "$GDIR" && glib-compile-resources --target=gnome-shell-theme.gresource rice.gresource.xml); then
    # kiểm tra file build được có đọc lại được không trước khi đăng ký
    if gresource list "$GDIR/gnome-shell-theme.gresource" >/dev/null 2>&1; then
      mkdir -p /usr/local/share/gnome-shell/theme/rice-catppuccin
      cp "$GDIR/gnome-shell-theme.gresource" /usr/local/share/gnome-shell/theme/rice-catppuccin/
      update-alternatives --install /usr/share/gnome-shell/gdm-theme.gresource gdm-theme.gresource \
        /usr/local/share/gnome-shell/theme/rice-catppuccin/gnome-shell-theme.gresource 200
      update-alternatives --set gdm-theme.gresource \
        /usr/local/share/gnome-shell/theme/rice-catppuccin/gnome-shell-theme.gresource
      log "GDM OK (alternative rice-catppuccin, file Yaru gốc không bị đụng)"
    else
      log "GDM: gresource build ra không hợp lệ — bỏ qua"; FAIL=1
    fi
  else
    log "GDM: glib-compile-resources lỗi — bỏ qua"; FAIL=1
  fi
else
  log "GDM: thiếu ảnh nền hoặc gresource gốc — bỏ qua"; FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then
  log "HOÀN TẤT install-system — reboot để thấy GRUB + Plymouth + GDM mới."
else
  log "XONG nhưng có mục lỗi ở trên — xem log. Rollback: sudo ./scripts/rollback.sh --system"
fi
