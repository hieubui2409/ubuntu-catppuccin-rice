#!/usr/bin/env bash
# fetch-assets.sh — Tải tarball theme GRUB + Plymouth (cần cho install-system.sh).
# Dùng gh (nếu đã login) để tránh rate-limit, fallback sang curl.
set -uo pipefail
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$REPO_DIR/assets"

fetch() {
  local repo="$1" out="$REPO_DIR/assets/catppuccin-$1.tar.gz"
  [ -s "$out" ] && { echo "✓ $repo đã có"; return; }
  if command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
    gh api "repos/catppuccin/$repo/tarball" > "$out" 2>/dev/null && { echo "✓ $repo (gh)"; return; }
  fi
  curl -fsSL --retry 3 -o "$out" "https://codeload.github.com/catppuccin/$repo/tar.gz/refs/heads/main" \
    && echo "✓ $repo (curl)" || { echo "✗ $repo LỖI"; rm -f "$out"; }
}

fetch grub
fetch plymouth
