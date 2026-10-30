// patina: the start menu in the middle of the screen's width, for a bar whose start
// button leads the task icons (panel.layout grouped with start_menu.position center in
// defaults/settings.yaml), installed by desktops/plasma/apply.sh as a KWin script.
// Plasma opens a panel popup centred over its button, and no window rule can move it:
// the start menu's window has no title, and the class and type of every panel popup.
// So this moves it once Plasma has placed it, and again when Plasma places it anew (a
// resize). The start menu is the panel popup that opens in the left three quarters of
// the screen: the tray and the clock, the bar's other popups, sit at its right end.
function centre(window) {
  var area = workspace.clientArea(KWin.MaximizeArea, window);
  var g = window.frameGeometry;
  var x = Math.round(area.x + (area.width - g.width) / 2);
  if (g.x !== x) {
    window.frameGeometry = {x: x, y: g.y, width: g.width, height: g.height};
  }
}

workspace.windowAdded.connect(function (window) {
  if (!window.appletPopup) {
    return;
  }
  var area = workspace.clientArea(KWin.MaximizeArea, window);
  var g = window.frameGeometry;
  if (g.x + g.width / 2 > area.x + area.width * 3 / 4) {
    return;
  }
  centre(window);
  window.frameGeometryChanged.connect(function () {
    centre(window);
  });
});
