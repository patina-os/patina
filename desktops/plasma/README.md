# desktops/plasma/

Renderer for KDE Plasma 6 as shipped by openSUSE. Nothing here yet except this contract;
`apply.sh` and `templates/` arrive with Phase 1 (`docs/roadmap.md`).

What it will produce from a theme and `defaults/`:

- a Plasma colour scheme (`~/.local/share/color-schemes/patina21-<theme>.colors`)
- a Konsole colour scheme and profile
- global shortcuts from `defaults/keybindings.yaml`
- look-and-feel, icon theme, cursor theme and wallpaper as the theme declares them
- GTK apps follow through Plasma's own GTK bridge; Flatpak apps through the portals

Tools it may call: `kwriteconfig6`, `plasma-apply-colorscheme`,
`plasma-apply-lookandfeel`, `plasma-apply-wallpaperimage`. All come from the openSUSE
repositories; nothing is downloaded.
