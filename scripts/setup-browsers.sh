#!/usr/bin/env bash
# setup-browsers.sh — Mở trang cài theme Catppuccin Mocha cho từng browser.
# Store không cho cài theme qua CLI, nên script mở đúng trang — bạn chỉ cần bấm "Add".

CHROME_THEME="https://chromewebstore.google.com/detail/catppuccin-chrome-theme-m/bkkmolkhemgaeaeggcmfbghljjjoofoh"
FIREFOX_THEME="https://addons.mozilla.org/en-US/firefox/addon/catppuccin-mocha-mauve/"

if command -v google-chrome >/dev/null; then
  echo "Chrome  → bấm 'Add to Chrome' ở tab vừa mở"
  google-chrome "$CHROME_THEME" >/dev/null 2>&1 &
fi

if command -v microsoft-edge >/dev/null; then
  echo "Edge    → bấm 'Allow extensions from other stores' (nếu hỏi) rồi 'Add to Chrome'"
  microsoft-edge "$CHROME_THEME" >/dev/null 2>&1 &
fi

if command -v firefox >/dev/null; then
  echo "Firefox → bấm 'Add' ở tab vừa mở"
  firefox "$FIREFOX_THEME" >/dev/null 2>&1 &
fi

echo "Xong — mỗi browser chỉ cần một cú click để nhận theme Catppuccin Mocha Mauve."
