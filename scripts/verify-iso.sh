#!/bin/bash
# Fails (non-zero) unless the ISO exists, is non-trivial, and carries the mandatory assets/config.
set -euo pipefail
ISO="${1:?usage: verify-iso.sh path/to.iso}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
fail(){ echo "FAIL: $*"; exit 1; }
[ -f "$ISO" ] || fail "ISO not found: $ISO"
SIZE=$(stat -c %s "$ISO"); echo "ISO size: $SIZE bytes"
[ "$SIZE" -gt 1000000000 ] || fail "ISO smaller than 1 GB (suspicious)"
if ! command -v xorriso >/dev/null || ! command -v unsquashfs >/dev/null; then
  export DEBIAN_FRONTEND=noninteractive; apt-get update -qq && apt-get install -y -qq xorriso squashfs-tools >/dev/null
fi
LIVE="$(xorriso -indev "$ISO" -ls /live 2>/dev/null || true)"
grep -q "filesystem.squashfs" <<<"$LIVE" || fail "/live/filesystem.squashfs missing in ISO"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
xorriso -osirrox on -indev "$ISO" -extract /boot/grub/grub.cfg "$T/grub.cfg" \
        -extract /live/filesystem.squashfs "$T/fs.squashfs" >/dev/null 2>&1 || fail "could not extract grub.cfg / filesystem.squashfs"
grep -q 'timeout=0' "$T/grub.cfg"        || fail "GRUB menu not hidden (timeout=0 missing)"
grep -q 'splash'    "$T/grub.cfg"        || fail "splash missing from kernel command line"
echo "ok   GRUB menu hidden, splash enabled"
# The kernel/initrd that grub.cfg points at must exist EXACTLY in /live (a loose match let a wrong name through once)
K=$(sed -n 's#^ *linux  */live/\([^ ]*\).*#\1#p' "$T/grub.cfg" | head -1)
R=$(sed -n 's#^ *initrd  */live/\([^ ]*\).*#\1#p' "$T/grub.cfg" | head -1)
[ -n "$K" ] && [ -n "$R" ] || fail "could not read kernel/initrd paths from grub.cfg"
NAMES="$(printf '%s\n' "$LIVE" | tr "' " '\n\n' | sed 's#.*/##')"   # fixed-string, one name per line (kernel names contain '+' and '.')
for n in "$K" "$R"; do
  grep -Fxq -- "$n" <<<"$NAMES" || { echo "listing of /live:"; echo "$LIVE"; fail "grub.cfg boots /live/$n but it does not exist in the ISO"; }
done
echo "ok   grub.cfg boots /live/$K + /live/$R and both exist in the ISO"
unsquashfs -l "$T/fs.squashfs" > "$T/list.txt" || fail "unsquashfs could not list the image"
echo "squashfs entries listed: $(wc -l < "$T/list.txt")"
missing=()
for f in usr/share/sequoia/logo.svg usr/share/sequoia/startup-sound.wav usr/share/sequoia/Hidden-Forest.mp4 \
         usr/share/sequoia/wallpaper-still.jpg usr/share/plymouth/themes/sequoia/logo.png \
         usr/share/plymouth/themes/sequoia/sequoia.script usr/lib/sequoia/startup-sound \
         usr/lib/systemd/user/sequoia-startup-sound.service usr/bin/sequoia-dock \
         etc/xdg/autostart/sequoia-dock.desktop usr/share/plasma/plasmoids/org.sequoia.logomenu/metadata.json \
         usr/share/plasma/wallpapers/org.sequoia.videowallpaper/metadata.json \
         usr/share/plasma/look-and-feel/org.sequoia.desktop/metadata.json \
         usr/share/sddm/themes/sequoia/Main.qml usr/share/color-schemes/SequoiaLight.colors \
         usr/share/fonts/opentype/sequoia/SF-Pro-Text-Regular.otf usr/lib/sequoia/live-autologin usr/lib/systemd/system/sequoia-live-autologin.service \
         usr/lib/sequoia/boot-sound usr/lib/systemd/system/sequoia-boot-sound.service etc/sequoia/startup-sound.conf \
         etc/systemd/system/multi-user.target.wants/sequoia-boot-sound.service usr/bin/aplay usr/bin/amixer \
         usr/share/applications/sequoia-install.desktop etc/xdg/autostart/sequoia-live-installer-icon.desktop \
         usr/share/icons/Sequoia/index.theme usr/bin/kmenuedit usr/bin/calamares etc/calamares/settings.conf etc/default/grub usr/lib/grub/x86_64-efi/normal.mod usr/lib/grub/i386-pc/boot.img usr/lib/grub/i386-pc/normal.mod; do
  if grep -Fxq "squashfs-root/$f" "$T/list.txt" || grep -Fxq "$f" "$T/list.txt"; then echo "ok   $f"
  else echo "MISSING $f"; missing+=("$f"); fi
done
if [ "${#missing[@]}" -gt 0 ]; then
  echo "--- diagnostics ---"
  echo "first 5 listing lines:"; head -5 "$T/list.txt"
  echo "listing lines containing 'sequoia' (max 40):"; grep -i sequoia "$T/list.txt" | head -40 || true
  echo "listing lines under usr/share/plymouth (max 10):"; grep 'usr/share/plymouth' "$T/list.txt" | head -10 || true
  fail "${#missing[@]} file(s) missing from the image: ${missing[*]}"
fi
if grep -Fxq "squashfs-root/etc/sddm.conf.d/20-live-autologin.conf" "$T/list.txt"; then fail "live autologin file is baked into the image (would be installed too)"; fi
echo "ok   no live autologin file baked into the image"
unsquashfs -d "$T/themecheck" -f "$T/fs.squashfs" etc/skel/.config/kdeglobals etc/skel/.config/kwinrc etc/skel/.config/sierrabreezeenhancedrc >/dev/null 2>&1 || fail "could not extract Sequoia Plasma theme defaults"
grep -q '^IconTheme=Sequoia' "$T/themecheck/etc/skel/.config/kdeglobals" || fail "Sequoia icon theme is not selected by default"
grep -q '^library=org.kde.sierrabreezeenhanced' "$T/themecheck/etc/skel/.config/kwinrc" || fail "Sierra Breeze Enhanced is not selected by default"
grep -q '^ButtonStyle=macSierra' "$T/themecheck/etc/skel/.config/sierrabreezeenhancedrc" || fail "macOS Sierra traffic-light button style is not selected by default"
echo "ok   Sequoia icon theme and macOS-style traffic-light decoration selected by default"
unsquashfs -d "$T/c" -f "$T/fs.squashfs" etc/calamares/modules/removeuser.conf etc/calamares/modules/users.conf etc/default/grub >/dev/null 2>&1 || true
grep -q '^username: live' "$T/c/etc/calamares/modules/removeuser.conf" 2>/dev/null || fail "Calamares removeuser is not set to remove the live user"
grep -q 'splash' "$T/c/etc/default/grub" 2>/dev/null || fail "/etc/default/grub lacks splash for installed systems"
echo "ok   installer removes live user; installed GRUB config has splash"
if grep -q '^allowWeakPasswords: true' "$T/c/etc/calamares/modules/users.conf" 2>/dev/null; then echo "ok   installer allows continuing past weak-password warnings"
else echo "NOTE installer weak-password setting not applied (users.conf missing or different)"; fi
if grep -Fq 'squashfs-root/var/cache/cracklib/cracklib_dict' "$T/list.txt"; then echo "ok   password dictionary (cracklib) is in the image"
else echo "NOTE password dictionary not found in the image; the installer's password check may complain"; fi
if grep -q 'org.kde.sierrabreezeenhanced' "$T/list.txt" && grep -q 'sierrabreezeenhanced.json' "$T/list.txt"; then
  echo "ok   Sierra Breeze Enhanced KWin decoration is in the image"
else
  fail "Sierra Breeze Enhanced window decoration is missing from the image"
fi
if grep -Fxq "squashfs-root/usr/share/icons/Sequoia/index.theme" "$T/list.txt" || grep -Fxq "usr/share/icons/Sequoia/index.theme" "$T/list.txt"; then
  echo "ok   Sequoia (WhiteSur-based) icon theme is in the image"
else
  fail "Sequoia icon theme is missing from the image"
fi
unsquashfs -d "$T/x" -f "$T/fs.squashfs" usr/share/sequoia/logo.svg usr/share/sequoia/startup-sound.wav usr/share/sequoia/Hidden-Forest.mp4 >/dev/null
for a in logo.svg startup-sound.wav Hidden-Forest.mp4; do
  cmp "$T/x/usr/share/sequoia/$a" "$HERE/assets/originals/$a" || fail "$a differs from supplied asset"
  echo "ok   $a identical to supplied asset"
done
echo "VERIFY PASSED (static checks only; boot/audio/UI must be tested in a VM, see docs/TESTING.md)"
