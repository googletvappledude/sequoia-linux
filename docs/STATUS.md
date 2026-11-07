# Status (honest)

Legend: BUILT = code written; TESTED = actually executed; none of the desktop pieces have been run yet.

| Item | State |
|---|---|
| Asset inspection, repo layout, live-build config | BUILT |
| Startup sound one-shot logic (once/boot, disable, races, restarts) | BUILT + TESTED with stub player (`tests/test_startup_sound.sh`) |
| Startup sound **real audio output** | NOT TESTED (no audio device/PipeWire in dev sandbox) |
| Plymouth black + centred logo | BUILT, NOT TESTED (needs VM); PNG is made at build time from logo.svg (white fill added since the SVG has no fill and would be black-on-black) |
| Hidden GRUB (timeout 0) | BUILT, NOT TESTED; verify-iso.sh checks it |
| SDDM theme, colour scheme, skel defaults, Plasma layout | BUILT, NOT TESTED |
| Logo menu plasmoid, video wallpaper plugin | BUILT, NOT TESTED (QML only linted in CI) |
| Dock (layer-shell, magnification, menus, autohide) | BUILT, NOT COMPILED yet; CI `components` job is the first compile |
| GitHub Actions: checks -> components -> iso -> verify -> upload | BUILT, NOT RUN |
| ISO | NOT BUILT yet. Dev sandbox has no network/live-build; CI must do it |

## Not started
Finder (custom file manager), Control Centre, System Settings app, notification styling, window decoration (traffic lights, rounded corners), Calamares config (must also delete `20-live-autologin.conf` on the target), widgets, other apps' theming.

## Known limitations / risks
- Wallpaper source video is 1280x720: low resolution on large displays.
- Startup sound plays at first graphical login of each boot (not pre-login like a Mac).
- LUKS disk encryption unsupported until Plymouth gets a password prompt (conflicts with "no text").
- Plasma layout JS `panel.opacity` may not exist in Plasma 6.3 (wrapped in try/catch).
- SF fonts and the startup sound may carry licences that forbid redistribution; keep the repo and ISOs private.
