// patina panel layout for Plasma 6, generated into the look-and-feel package from
// desktops/plasma/templates/layout.js. Plasma runs it for a session that has no panels
// yet (the first login) and on `patina theme set --layout`. One bar at the bottom, the
// launcher and the task icons in the centre, the tray and the clock at the right.
var panel = new Panel;
panel.location = "bottom";
panel.alignment = "center";
panel.lengthMode = "fill";
panel.floating = ${PANEL_FLOATING};
panel.hiding = "none";
panel.height = 2 * Math.ceil(gridUnit * 2.5 / 2);

panel.addWidget("org.kde.plasma.panelspacer");
// The start menu (Kickoff, or the Application Dashboard for start_menu.style dashboard):
// the patina mark as its button, the favourites first (AI and self-hosting, from
// kicker-extra-favoritesrc); in Kickoff as a grid of apps by their names alone, compact
// lists, and one power button without a caption (shut down; sleep, restart and log out
// in its menu), as little around the apps as Kickoff's settings allow.
var launcher = panel.addWidget("${LAUNCHER_APPLET}");
launcher.currentConfigGroup = ["General"];
launcher.writeConfig("icon", "${LAUNCHER_ICON}");
if ("${LAUNCHER_APPLET}" === "org.kde.plasma.kickoff") {
  launcher.writeConfig("favoritesDisplay", 0);
  launcher.writeConfig("applicationsDisplay", 1);
  launcher.writeConfig("appNameFormat", 0);
  launcher.writeConfig("compactMode", true);
  launcher.writeConfig("primaryActions", 2);
  launcher.writeConfig("systemFavorites", ["shutdown"]);
  launcher.writeConfig("showActionButtonCaptions", false);
  launcher.writeConfig("switchCategoryOnHover", true);
}
var tasks = panel.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [${PINNED_LAUNCHERS}]);
panel.addWidget("org.kde.plasma.panelspacer");
panel.addWidget("org.kde.plasma.marginsseparator");
panel.addWidget("org.kde.plasma.systemtray");
panel.addWidget("org.kde.plasma.digitalclock");
panel.addWidget("org.kde.plasma.showdesktop");

// The theme's wallpaper: a first login takes the look-and-feel package's layout but not
// its wallpaper, so the script sets it on every desktop.
var desktops = desktopsForActivity(currentActivity());
for (var i = 0; i < desktops.length; i++) {
  desktops[i].wallpaperPlugin = "org.kde.image";
  if ("${WALLPAPER_PACKAGE}" !== "") {
    desktops[i].currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desktops[i].writeConfig("Image", "file://${WALLPAPER_PACKAGE}");
  }
}
