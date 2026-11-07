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
for f in vmlinuz initrd.img filesystem.squashfs; do
  grep -q "$f" <<<"$LIVE" || fail "/live/$f missing in ISO (GRUB entry would not boot)"
done
echo "ok   /live has vmlinuz, initrd.img, filesystem.squashfs"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
xorriso -osirrox on -indev "$ISO" -extract /boot/grub/grub.cfg "$T/grub.cfg" \
        -extract /live/filesystem.squashfs "$T/fs.squashfs" >/dev/null 2>&1 || fail "could not extract grub.cfg / filesystem.squashfs"
grep -q 'timeout=0' "$T/grub.cfg"        || fail "GRUB menu not hidden (timeout=0 missing)"
grep -q 'splash'    "$T/grub.cfg"        || fail "splash missing from kernel command line"
echo "ok   GRUB menu hidden, splash enabled"
unsquashfs -l "$T/fs.squashfs" > "$T/list.txt"
for f in usr/share/sequoia/logo.svg usr/share/sequoia/startup-sound.wav usr/share/sequoia/Hidden-Forest.mp4 \
         usr/share/sequoia/wallpaper-still.jpg usr/share/plymouth/themes/sequoia/logo.png \
         usr/share/plymouth/themes/sequoia/sequoia.script usr/lib/sequoia/startup-sound \
         usr/lib/systemd/user/sequoia-startup-sound.service usr/bin/sequoia-dock \
         etc/xdg/autostart/sequoia-dock.desktop usr/share/plasma/plasmoids/org.sequoia.logomenu/metadata.json \
         usr/share/plasma/wallpapers/org.sequoia.videowallpaper/metadata.json \
         usr/share/plasma/look-and-feel/org.sequoia.desktop/metadata.json \
         usr/share/sddm/themes/sequoia/Main.qml usr/share/color-schemes/SequoiaLight.colors \
         usr/share/fonts/opentype/sequoia/SF-Pro-Text-Regular.otf etc/sddm.conf.d/20-live-autologin.conf; do
  grep -Fxq "squashfs-root/$f" "$T/list.txt" && echo "ok   $f" || fail "missing in image: $f"
done
unsquashfs -d "$T/x" -f "$T/fs.squashfs" usr/share/sequoia/logo.svg usr/share/sequoia/startup-sound.wav usr/share/sequoia/Hidden-Forest.mp4 >/dev/null
for a in logo.svg startup-sound.wav Hidden-Forest.mp4; do
  cmp "$T/x/usr/share/sequoia/$a" "$HERE/assets/originals/$a" || fail "$a differs from supplied asset"
  echo "ok   $a identical to supplied asset"
done
echo "VERIFY PASSED (static checks only; boot/audio/UI must be tested in a VM, see docs/TESTING.md)"
