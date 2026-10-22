# desktops/terminal/

Not a desktop: the renderer for what every desktop shares, the terminal and the tools
that run in it. `patina theme set` and `patina install` run `apply.sh <theme-dir>` for
the current user before the desktop's own renderer, so Plasma today and Hyprland later
(Phase 7) get the same terminal from the same theme data. A desktop renderer may point
at these files (Plasma's agent launcher opens the agent's kitty profile) but never
writes them.

## The approach: the terminal carries the palette

kitty gets the theme's base16 palette as its sixteen colours plus the base16 extras as
colours 16 to 21, the layout base16-shell uses. Every tool that draws with the
terminal's colours then follows any theme without a file of its own: eza, starship,
lazygit, atuin and zoxide do so out of the box, bat, git-delta and fzf after one
setting each. Only the tools that draw in 24-bit colour get a file per theme: btop and
neovim.

## What it produces

- kitty: `~/.config/kitty/patina21.conf` (colours and fonts), included from `kitty.conf`;
  the include line is added once, above whatever the user keeps there
- with the agents bundle: `~/.config/kitty/patina21-agent.conf`, a quieter kitty profile
  from the same palette for the agent CLI; removed again when the bundle is not
  installed
- the fastfetch greeting: `~/.local/share/patina21/logo.txt`, the text mark in the
  brand's colours (`print_logo always`), and `~/.config/fastfetch/config.jsonc`
  pointing at it with the theme's accent for the labels
- btop: `~/.config/btop/themes/patina21-<theme>.theme`, its load gradients running
  from `base0D` through the accent (`base0E`) to `base0F`, made `color_theme` in
  `btop.conf` while that is btop's `Default` or a patina21 theme; a theme the user
  picked stays. btop rewrites `btop.conf` itself and keeps the key
- neovim: the colour scheme `~/.config/nvim/colors/patina21-<theme>.lua` (editor, syntax
  after the base16 styling guide, tree-sitter, diagnostics, diffs, the built-in
  terminal's colours) and `~/.config/nvim/plugin/patina21.lua`, which turns it on only
  when the user's configuration chose no colour scheme
- bat: `~/.config/bat/config` with the `base16-256` theme, which draws with the
  terminal's colours
- the session's environment, `~/.config/environment.d/60-patina21.conf`, read by
  systemd's user manager at login: `FZF_DEFAULT_OPTS=--color=16` and
  `BAT_THEME=base16-256` for git-delta. A value the user's shell sets wins

Files in the user's own places (`fastfetch/config.jsonc`, the neovim plugin, the bat
configuration, the environment file) are written only while their first line carries
`patina21:`; a user who removes that line keeps the file as they leave it. Files named
after the theme are removed when another theme is set.

## Reload

kitty reads its configuration at start (`ctrl+shift+F5` reloads a running one); btop
and neovim pick the theme up at their next start; the environment file applies from the
next login. Nothing is restarted for the user.

Tools it calls: none beyond bash, coreutils, `sed` and the Go `yq`. Nothing is
downloaded.
