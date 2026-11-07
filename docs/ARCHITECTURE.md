# Architecture (decisions)

| Layer | Choice | Why |
|---|---|---|
| Base | Debian 13 stable | Stability; Plasma 6.3, Qt 6.8, PipeWire, Calamares all packaged |
| ISO tooling | live-build, `iso-hybrid`, GRUB (BIOS+UEFI) | Debian-native; one bootloader to hide for a black boot |
| Compositor/WM | KWin (Wayland) | Blur, translucency, animations built in; mature HiDPI/suspend |
| Shell | Plasma 6, top panel = menu bar | Real global menu (`appmenu`), tray (Wi-Fi/BT/volume/battery), notifications, KRunner for Spotlight-like launcher |
| Menu-bar logo | Custom plasmoid `org.sequoia.logomenu` | Renders `/usr/share/sequoia/logo.svg` directly |
| Dock | Custom Qt Quick app `sequoia-dock` + LayerShellQt | Plasma panels cannot magnify; uses libtaskmanager for running/minimise state |
| Wallpaper | Custom QML wallpaper plugin (QtMultimedia) | Video with static fallback; pauses on battery |
| Boot splash | Plymouth `script` theme | Black bg, centred logo, no other drawing |
| Login | SDDM (Qt6) custom theme | Lock-screen look per reference screenshot |
| Installer | Calamares | Standard for live-build distros (config: TODO) |
| Fonts | SF Pro (from supplied zip) + Noto fallback | Installed by build hook |

Components are separate packages/plugins, not one monolith. Finder, Control Centre and Settings will be separate Qt Quick apps.
