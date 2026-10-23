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
panel.addWidget("org.kde.plasma.kickoff");
var tasks = panel.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [${PINNED_LAUNCHERS}]);
panel.addWidget("org.kde.plasma.panelspacer");
panel.addWidget("org.kde.plasma.marginsseparator");
panel.addWidget("org.kde.plasma.systemtray");
panel.addWidget("org.kde.plasma.digitalclock");
panel.addWidget("org.kde.plasma.showdesktop");

var desktops = desktopsForActivity(currentActivity());
for (var i = 0; i < desktops.length; i++) {
  desktops[i].wallpaperPlugin = "org.kde.image";
}
