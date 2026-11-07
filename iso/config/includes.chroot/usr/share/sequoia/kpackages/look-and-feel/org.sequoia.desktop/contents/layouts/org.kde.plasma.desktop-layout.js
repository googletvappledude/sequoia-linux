// Top menu bar. The Dock is a separate process (sequoia-dock), not a Plasma panel.
var bar = new Panel;
bar.location = "top";
bar.height = 26;
bar.floating = false;
bar.hiding = "none";
try { bar.opacity = "translucent"; } catch (e) {}
bar.addWidget("org.sequoia.logomenu");
bar.addWidget("org.kde.plasma.appmenu");      // global application menus
bar.addWidget("org.kde.plasma.panelspacer");
bar.addWidget("org.kde.plasma.systemtray");   // Wi-Fi, Bluetooth, volume, battery, notifications
bar.addWidget("org.kde.plasma.digitalclock");

var desks = desktopsForActivity(currentActivity());
for (var i = 0; i < desks.length; i++) {
    var d = desks[i];
    d.wallpaperPlugin = "org.sequoia.videowallpaper";
    d.currentConfigGroup = ["Wallpaper", "org.sequoia.videowallpaper", "General"];
    d.writeConfig("VideoUrl", "file:///usr/share/sequoia/Hidden-Forest.mp4");
    d.writeConfig("StillUrl", "file:///usr/share/sequoia/wallpaper-still.jpg");
}
