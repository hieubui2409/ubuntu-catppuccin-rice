# catppuccin-cli.zsh — Catppuccin Mocha cho các CLI tool (fzf, eza, forgit...)
# Được source từ ~/.zshrc (dòng do rice thêm vào).

# fzf — Catppuccin Mocha (mauve accent)
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:-} \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a \
--color=border:#6c7086,label:#cdd6f4"

# eza — nhấn mauve/lavender cho dir & symlink
export EZA_COLORS="di=1;38;2;203;166;247:ln=38;2;180;190;254:ex=1;38;2;166;227;161"

# GREP màu match hồng Catppuccin
export GREP_COLORS='ms=1;38;2;245;194;231'
