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

- kitty: `~/.config/kitty/patina.conf` (colours, fonts, padding and a slightly
  see-through background, the one see-through window of the desktop; the size of a new
  window is left to the desktop), included from `kitty.conf`;
  the include line is added once, above whatever the user keeps there
- with an AI bundle (`ai-local`, `ai-cloud`) or the agents bundle:
  `~/.config/kitty/patina-agent.conf`, a quieter kitty profile from the same palette
  for the agent; removed again when none of them is installed
- the fastfetch greeting: `~/.local/state/patina/logo.txt`, the text mark in the
  brand's colours for the mode's ground (`print_logo always <variant>`), and
  `~/.config/fastfetch/config.jsonc` pointing at it with the theme's accent for the
  labels; every new kitty window runs it, through two lines added once at the end of
  `~/.bashrc` and `~/.config/fish/conf.d/patina-greeting.fish`
- btop: `~/.config/btop/themes/patina-<theme>.theme`, its load gradients running
  from `base0D` through the accent to its second colour (`accent` and `accent_alt`
  of the theme), made `color_theme` in
  `btop.conf` while that is btop's `Default` or a patina theme; a theme the user
  picked stays. btop rewrites `btop.conf` itself and keeps the key
- neovim: the colour scheme `~/.config/nvim/colors/patina-<theme>.lua` (editor, syntax
  after the base16 styling guide, tree-sitter, diagnostics, diffs, the built-in
  terminal's colours) and `~/.config/nvim/plugin/patina.lua`, which turns it on only
  when the user's configuration chose no colour scheme
- bat: `~/.config/bat/config` with the `base16-256` theme, which draws with the
  terminal's colours
- the session's environment, `~/.config/environment.d/60-patina.conf`, read by
  systemd's user manager at login: `~/.local/bin` on the `PATH`, `FZF_DEFAULT_OPTS=--color=16` and
  `BAT_THEME=base16-256` for git-delta. A value the user's shell sets wins

Files in the user's own places (`fastfetch/config.jsonc`, the neovim plugin, the bat
configuration, the environment file) are written only while their first line carries
`patina:`; a user who removes that line keeps the file as they leave it. Files named
after the theme are removed when another theme is set.

## Reload

kitty reads its configuration at start (`ctrl+shift+F5` reloads a running one); btop
and neovim pick the theme up at their next start; the environment file applies from the
next login. Nothing is restarted for the user.

Tools it calls: none beyond bash, coreutils, `sed` and the Go `yq`. Nothing is
downloaded.
