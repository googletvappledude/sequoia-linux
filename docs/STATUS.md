# Status (honest)

Legend: BUILT = code written; TESTED = actually executed; none of the desktop pieces have been run yet.

| Item | State |
|---|---|
| Asset inspection, repo layout, live-build config | BUILT |
| Startup sound one-shot logic (once/boot, disable, races, restarts) | BUILT + TESTED with stub player (`tests/test_startup_sound.sh`) |
| Startup sound at boot (system service, plays via ALSA during the splash) + login-time fallback | BUILT; logic TESTED with stubs (tests/test_boot_sound.sh). Real audio output NOT TESTED; Chromebook/odd codecs may need extra setup. Starts ~1-5 s after the logo appears, not at the exact instant |
| Plymouth black + centred logo | BUILT, NOT TESTED (needs VM); PNG is made at build time from logo.svg (white fill added since the SVG has no fill and would be black-on-black) |
| Hidden GRUB (timeout 0) | BUILT, NOT TESTED; verify-iso.sh checks it |
| SDDM theme, colour scheme, skel defaults, Plasma layout | BUILT, NOT TESTED |
| Logo menu plasmoid, video wallpaper plugin | BUILT, NOT TESTED (QML only linted in CI) |
| Dock (layer-shell, magnification, menus, autohide) | BUILT, NOT COMPILED yet; CI `components` job is the first compile |
| GitHub Actions: checks -> components -> iso -> verify -> upload | BUILT, NOT RUN |
| ISO | Built by CI (1.6 GB). Boot/UI behaviour NOT yet observed by me |
| Installer (Calamares from calamares-settings-debian + our hook) | BUILT, NOT TESTED. Launcher: desktop icon (live only) + menu entry `Install Sequoia Linux` |
| Live autologin | Live-only systemd service; file is never in the image, so installed systems don't autologin |

## Not started
Finder (custom file manager), Control Centre, System Settings app, notification styling, window decoration (traffic lights, rounded corners), Calamares branding (uses Debian's), widgets, other apps' theming.

## Known limitations / risks
- Wallpaper source video is 1280x720: low resolution on large displays.
- Startup sound plays at first graphical login of each boot (not pre-login like a Mac).
- LUKS disk encryption unsupported until Plymouth gets a password prompt (conflicts with "no text").
- Plasma layout JS `panel.opacity` may not exist in Plasma 6.3 (wrapped in try/catch).
- SF fonts and the startup sound may carry licences that forbid redistribution; keep the repo and ISOs private.

## Installer limitations
- Secure Boot: not supported; disable it in firmware. No LUKS encryption. BIOS and UEFI installs are untested.
- Installed GRUB menu is hidden with a 2 s window (Shift/Esc shows it). Dual-boot: other systems are detected by os-prober but the menu stays hidden.
- Test only in a VM with a blank virtual disk first. Never test the installer on a disk with data you need.

## Startup sound
- Setting: /etc/sequoia/startup-sound.conf (enabled=true|false, persists across reboots). The Settings app will write it later; until then edit with sudo.
- The login-time service only plays if the boot service did not (shared flag in /run), so it plays once per boot.
