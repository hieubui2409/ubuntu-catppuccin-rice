# 🌸 Ubuntu Catppuccin Rice — Mocha Mauve

A complete **Catppuccin Mocha (Mauve accent)** desktop for **Ubuntu 24.04 / GNOME 46 (Wayland)** — the GNOME twin of my [kubuntu-catppuccin-rice](https://github.com/hieubui2409/kubuntu-catppuccin-rice) homelab setup. Every surface themed: windows, panel, dock, terminal, editor, browsers, login screen, boot splash and GRUB — without breaking anything, and with a full rollback path.

> Built on an HP ProBook 440 G11 (Intel Meteor Lake iGPU).

## ✨ What's themed

| Surface | What | Source |
|---|---|---|
| GTK 3/4 + libadwaita | `catppuccin-mocha-mauve-standard` + gtk-4.0 asset links | [catppuccin/gtk] |
| Shell theme | Same theme via User Themes extension | [catppuccin/gtk] |
| Icons | Tela-circle purple dark | [vinceliuice/Tela-circle-icon-theme] |
| Cursors | Catppuccin Mocha Mauve | [catppuccin/cursors] |
| Top panel | **Open Bar** — floating rounded bar, Mocha base, mauve accents, styled menus | [neuromorph/openbar] |
| Panel auto-hide | **Hide Top Bar** — intellihide (hides when a window touches it), reveal on pressure/overview | [tuxor1337/hidetopbar] |
| Dock | Dash-to-Dock bottom floating, Mocha background, mauve running dots + blur | built-in ext + Blur My Shell |
| Blur | **Blur My Shell** — overview + dock blur | [aunetx/blur-my-shell] |
| Window corners | **Rounded Window Corners Reborn** | [fxgn/rounded-window-corners] |
| Open/Close FX | **Burn-My-Windows** — Aura Glow on both open and close | [Schneegans/Burn-My-Windows] |
| Wobbly windows | **Compiz windows effect** — same jelly drag as the KDE wobbly windows | [hermes83/compiz-windows-effect] |
| Minimize FX | **Compiz-alike Magic Lamp** — genie minimize to the dock | [hermes83/compiz-alike-magic-lamp-effect] |
| Workspace cube | **Desktop Cube** — 4 fixed workspaces on a 3D cube | [Schneegans/Desktop-Cube] |
| Media controls | **Media Controls** in the top bar (player + track like the KDE panel) | [cliffniff/media-controls] |
| Peek desktop | Bottom-right hot corner → show desktop via **Custom Hot Corners Extended** | [G-dH/custom-hot-corners-extended] |
| Net speed | **com.hieubt.netspeed** — my own GJS extension, a port of the Plasma applet: fixed-width ↓/↑ rows, peach/teal, left side of the panel | `gnome/extensions/` |
| Monitors | **Vitals** in-panel CPU / RAM | pre-installed ext, configured |
| Clock | `yyyy-mm-dd HH:MM:SS` via `LC_TIME=en_DK` (ISO 8601) + seconds enabled | scripted |
| Dropdown terminal | **ddterm** (Yakuake stand-in) — full Mocha palette, 88% opacity | pre-installed ext, configured |
| Wallpaper | 8 walls from walls-catppuccin-mocha on a native 30-min slideshow | [orangci/walls-catppuccin-mocha] |
| Fonts | Inter (UI) + CaskaydiaCove Nerd Font (mono) | [rsms/inter] |
| Terminal | Ghostty `catppuccin-mocha` (opacity + blur kept) | built-in theme |
| Shell prompt | Powerlevel10k Catppuccin overrides (zsh) | `configs/zsh/` |
| CLI | fzf, eza, grep colors, bat, btop, fastfetch, tmux — all Mocha | `configs/` |
| Editor | VS Code Catppuccin theme + icons, Nerd Font ligatures | `configs/vscode/` |
| Editor 2 | Kate — Catppuccin Mocha (upstream KDE theme file) + Nerd Font | `configs/kate/` |
| Browsers | Catppuccin Mocha for Chrome / Edge / Firefox (one-click) | `scripts/setup-browsers.sh` |
| Flatpak | GTK theme / icons / cursor forwarded via overrides | scripted |
| GDM login | Catppuccin wallpaper via a **safe `update-alternatives` gresource** (Yaru untouched) | `scripts/install-system.sh` |
| Boot | GRUB [catppuccin/grub] + Plymouth [catppuccin/plymouth] | `scripts/install-system.sh` |

## 📦 Layout

```
gnome/       dconf-rice.ini (all GNOME + extension settings), Burn-My-Windows profiles,
             extensions/com.hieubt.netspeed (my own GJS net-speed indicator)
configs/     ghostty, zsh (p10k overrides + CLI colors), bat, btop, fastfetch, tmux, vscode
wallpapers/  8 selected Catppuccin Mocha walls
scripts/     install-*.sh (user-space), install-system.sh (sudo), rollback.sh, fetch-assets.sh
logs/        install logs from my machine
```

## 🚀 Install

Everything user-side is reversible; system-side goes through backups + `update-alternatives`.

```bash
# 1. Base themes: GTK, icons, cursors, Inter font, wallpapers, btop/fastfetch
./scripts/install-base-themes.sh

# 2. GNOME extensions: Blur My Shell, Burn My Windows, Open Bar, rounded corners, User Themes, Hide Top Bar
./scripts/install-extensions.sh

# 3. Apply everything: dconf, dock, panel, wallpaper slideshow, GTK4 links, Flatpak overrides
./scripts/apply-gnome-settings.sh

# 4. Terminal & CLI stack
./scripts/install-cli-theme.sh

# 5. Log out & back in (Wayland needs it to load the new extensions)

# 6. Boot chain + login screen (GRUB, Plymouth, GDM) — read it first!
./scripts/fetch-assets.sh
sudo ./scripts/install-system.sh

# 7. Browsers — opens the store page in each browser, you click "Add"
./scripts/setup-browsers.sh
```

VS Code: `code --install-extension Catppuccin.catppuccin-vsc Catppuccin.catppuccin-vsc-icons`, then merge `configs/vscode/settings.json`.

## ⏪ Rollback

```bash
./scripts/rollback.sh                 # user-space: dconf + configs from backups/<date>/
sudo ./scripts/rollback.sh --system   # + GRUB, Plymouth, GDM (alternatives removed, stock restored)
```

`backups/` (created on first run, git-ignored) holds a full dconf dump and copies of every touched config.

## 🎨 Palette

Catppuccin **Mocha**, accent **Mauve** `#cba6f7` — base `#1e1e2e`, surface `#313244`, text `#cdd6f4`, blue `#89b4fa`, green `#a6e3a1`, peach `#fab387`, teal `#94e2d5`.

## 🙏 Credits

- [Catppuccin](https://github.com/catppuccin) — gtk, cursors, grub, plymouth, bat, btop, vscode, browsers
- [neuromorph/openbar], [aunetx/blur-my-shell], [fxgn/rounded-window-corners], [Schneegans/Burn-My-Windows] — the GNOME shell magic
- [vinceliuice/Tela-circle-icon-theme] — icons
- [orangci/walls-catppuccin-mocha] — wallpapers
- [rsms/inter] — the Inter font family

## 📄 License

My own scripts and configs: MIT. Third-party themes keep their upstream licenses (see Credits).

[catppuccin/gtk]: https://github.com/catppuccin/gtk
[catppuccin/cursors]: https://github.com/catppuccin/cursors
[catppuccin/grub]: https://github.com/catppuccin/grub
[catppuccin/plymouth]: https://github.com/catppuccin/plymouth
[vinceliuice/Tela-circle-icon-theme]: https://github.com/vinceliuice/Tela-circle-icon-theme
[neuromorph/openbar]: https://github.com/neuromorph/openbar
[tuxor1337/hidetopbar]: https://gitlab.gnome.org/tuxor1337/hidetopbar
[hermes83/compiz-windows-effect]: https://github.com/hermes83/compiz-windows-effect
[hermes83/compiz-alike-magic-lamp-effect]: https://github.com/hermes83/compiz-alike-magic-lamp-effect
[Schneegans/Desktop-Cube]: https://github.com/Schneegans/Desktop-Cube
[cliffniff/media-controls]: https://github.com/sakithb/media-controls
[G-dH/custom-hot-corners-extended]: https://github.com/G-dH/custom-hot-corners-extended
[aunetx/blur-my-shell]: https://github.com/aunetx/blur-my-shell
[fxgn/rounded-window-corners]: https://github.com/flexagoon/rounded-window-corners
[Schneegans/Burn-My-Windows]: https://github.com/Schneegans/Burn-My-Windows
[orangci/walls-catppuccin-mocha]: https://github.com/orangci/walls-catppuccin-mocha
[rsms/inter]: https://github.com/rsms/inter
