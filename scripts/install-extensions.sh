#!/usr/bin/env bash
# install-extensions.sh — Cài GNOME extensions cho rice (GNOME 46, user-space)
# Blur My Shell, Burn My Windows, Open Bar, Rounded Window Corners Reborn, User Themes
set -uo pipefail

WORK="${TMPDIR:-/tmp}/rice-extensions"
mkdir -p "$WORK"
SHELL_VER=$(gnome-shell --version | grep -oE '[0-9]+' | head -1)
log() { echo "[$(date +%H:%M:%S)] $*"; }

UUIDS=(
  "blur-my-shell@aunetx"
  "burn-my-windows@schneegans.github.com"
  "openbar@neuromorph"
  "rounded-window-corners@fxgn"
  "user-theme@gnome-shell-extensions.gcampax.github.com"
  "hidetopbar@mathieu.bidon.ca"
  "compiz-windows-effect@hermes83.github.com"
  "compiz-alike-magic-lamp-effect@hermes83.github.com"
  "desktop-cube@schneegans.github.com"
  "mediacontrols@cliffniff.github.com"
  "custom-hot-corners-extended@G-dH.github.com"
)

for uuid in "${UUIDS[@]}"; do
  if gnome-extensions list | grep -q "^$uuid$"; then
    log "$uuid đã cài"
    continue
  fi
  log "Tải $uuid..."
  info=$(curl -fsSL "https://extensions.gnome.org/extension-info/?uuid=${uuid}&shell_version=${SHELL_VER}")
  dl=$(echo "$info" | python3 -c "import sys,json; print(json.loads(sys.stdin.read(), strict=False).get('download_url',''))" 2>/dev/null)
  if [ -z "$dl" ]; then
    log "  !! Không tìm thấy bản cho GNOME $SHELL_VER: $uuid"
    continue
  fi
  curl -fsSL -o "$WORK/${uuid}.zip" "https://extensions.gnome.org${dl}" \
    && gnome-extensions install --force "$WORK/${uuid}.zip" \
    && log "  ✓ đã cài $uuid" || log "  !! LỖI cài $uuid"
done

# Bật tất cả (có hiệu lực đầy đủ sau khi đăng xuất/đăng nhập lại trên Wayland)
current=$(gsettings get org.gnome.shell enabled-extensions)
python3 - "$current" "${UUIDS[@]}" <<'EOF'
import ast, subprocess, sys
cur = ast.literal_eval(sys.argv[1]) if sys.argv[1] != '@as []' else []
for u in sys.argv[2:]:
    if u not in cur:
        cur.append(u)
subprocess.run(["gsettings", "set", "org.gnome.shell", "enabled-extensions", str(cur)], check=True)
EOF
log "Đã thêm vào enabled-extensions (cần logout/login để nạp)."
