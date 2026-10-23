# dotfiles

My Arch Linux + Hyprland setup: window manager, bar, Quickshell panels, theming,
terminal, shell and Neovim. Everything under `dotfiles/` is linked into `$HOME`
with GNU Stow, so editing a file in `~/.config` edits it in this repo.

## Credits

This project started as a fork of [**filip-rs/arch-dotfiles**](https://github.com/filip-rs/arch-dotfiles)
by **Filip R. Spanne**. A big thank-you to Filip for the groundwork. The structure,
the theme engine and most of the original configs are his, and this setup would
not exist without them. Files I have since rewritten or changed are marked
`Maintained by Magnus Naessan Gaarder, based on work by Filip R. Spanne`.

The Quickshell panels (`hypr/scripts/quickshell/`) are the creation of
[ilyamiro](https://github.com/ilyamiro/nixos-configuration).

## What's inside

| Path | What it configures |
|---|---|
| `dot-config/hypr/` | Hyprland (Lua config), hyprlock, hypridle, theme engine and helper scripts |
| `dot-config/hypr/scripts/quickshell/` | Popups: network/Bluetooth, volume, battery, calendar + weather, music, wallpapers, monitors, cheat sheet |
| `dot-config/waybar/`, `swaync/`, `wofi/`, `wlogout/` | Bar, notifications, app launcher, logout menu |
| `dot-config/nwg-dock-hyprland/`, `nwg-look/` | Auto-hiding app dock, GTK appearance settings |
| `dot-config/ghostty/`, `dot-zshrc`, `dot-tmux.conf` | Terminal, zsh (oh-my-zsh + starship), tmux |
| `dot-config/nvim/` | Neovim (lazy.nvim) |
| `dot-config/fastfetch/`, `pacseek/`, `matugen/` | System info, terminal package browser, wallpaper colour generation |
| `pkglist.txt`, `pkglist-aur.txt` | Packages these dotfiles need |
| `tools/`, `systemd/`, `.githooks/` | Integrity check and weekly backup |

## Installation

> **Take a backup of your existing `~/.config` first.** Stow refuses to overwrite
> real files, but you may have to move some aside.

1. **Clone**

   ```bash
   git clone https://github.com/MagnusNaessanGaarder/dotfiles.git ~/Dotfiles
   cd ~/Dotfiles
   ```

2. **Install packages.** Official repos first, then the AUR. `paru` itself comes
   from the AUR, so bootstrap it once if you don't have it
   ([instructions](https://github.com/Morganamilo/paru#installation)).

   ```bash
   grep -v '^#' pkglist.txt | sudo pacman -S --needed -
   grep -v '^#' pkglist-aur.txt | paru -S --needed -
   ```

3. **Link the configs.** Most folders in `~/.config` become links into this repo, so
   new files you create there land in the repo too.

   ```bash
   cd ~/Dotfiles/dotfiles
   stow . --dotfiles -t "$HOME"
   ```

4. **Machine-specific files** (gitignored, so each machine creates its own)

   ```bash
   touch ~/.config/hypr/local.lua                         # per-machine Hyprland overrides
   ~/.config/hypr/scripts/theme_apply.sh catppuccin-mocha # generates all colour files
   cp ~/.config/hypr/scripts/quickshell/calendar/.env.example \
      ~/.config/hypr/scripts/quickshell/calendar/.env     # then add your OpenWeather key
   ```

   Monitor layouts saved from the Monitors popup (`SUPER+CTRL+M`) are written to
   `~/.config/hypr/monitors.lua`, which also stays out of git.

5. **zsh:** install [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh) into the folder `.zshrc` expects, then switch shell

   ```bash
   git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.config/zsh/ohmyzsh
   chsh -s /usr/bin/zsh
   ```

6. **tmux:** install the plugin manager, start tmux, then press `Ctrl+Space` followed by `Shift+I` to install the plugins

   ```bash
   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
   ```

   The prefix is `Ctrl+Space`. `prefix + r` reloads the config.

7. **pacseek:** installed by the AUR list. Run `pacseek` to browse, install and
   remove packages. It uses `paru` for installs.

8. **Neovim:** start `nvim` once; lazy.nvim installs all plugins on the first launch.

9. Log out and back in to Hyprland.

## Integrity check and automatic backups

`tools/check.sh` validates the repo before anything reaches GitHub. It checks:

- no `.env` files, private keys, API tokens or plain-text passwords
- [gitleaks](https://github.com/gitleaks/gitleaks) finds no secrets in the files or anywhere in the git history (a secret that was committed and later deleted is still public)
- no files over 20 MB
- shell, Python, Lua and JSON syntax
- with `--full`, that Neovim starts without errors

It runs in three places:

- **Before every push**, via a git hook. Enable it once per clone:

  ```bash
  git config core.hooksPath .githooks
  ```

- **Every Monday at 12:00**, via a systemd timer that runs `tools/backup.sh`.
  If anything changed and the check passes, it commits and pushes, then sends
  a desktop notification. If the check fails, nothing is committed. A missed
  run (laptop off) happens at the next login.

  ```bash
  systemctl --user link ~/Dotfiles/systemd/dotfiles-backup.service
  systemctl --user enable --now ~/Dotfiles/systemd/dotfiles-backup.timer
  systemctl --user list-timers dotfiles-backup.timer   # shows the next run
  ```

  Pushing from the timer needs `gh auth login` and `gh auth setup-git` done once.

- **On GitHub**, via Actions (`.github/workflows/check.yml`), to catch pushes
  made without the hook.

## License

MIT, see [LICENSE](LICENSE). Copyright Filip R. Spanne and Magnus Naessan Gaarder.
