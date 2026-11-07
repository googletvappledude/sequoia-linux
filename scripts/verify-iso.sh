#!/bin/bash
# Fails (non-zero) unless the ISO exists, is non-trivial, and carries the mandatory assets/config.
set -euo pipefail
ISO="${1:?usage: verify-iso.sh path/to.iso}"
[ -f "$ISO" ] || { echo "FAIL: ISO not found: $ISO"; exit 1; }
SIZE=$(stat -c %s "$ISO"); echo "ISO size: $SIZE bytes"
[ "$SIZE" -gt 1000000000 ] || { echo "FAIL: ISO smaller than 1 GB (suspicious)"; exit 1; }
command -v xorriso >/dev/null || apt-get install -y xorriso squashfs-tools >/dev/null
xorriso -indev "$ISO" -find / -maxdepth 2 2>/dev/null | grep -q '/live' || { echo "FAIL: no /live directory in ISO"; exit 1; }
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
xorriso -osirrox on -indev "$ISO" -extract /boot/grub/grub.cfg "$T/grub.cfg" -extract /live/filesystem.squashfs "$T/fs.squashfs" 2>/dev/null
grep -q 'timeout=0' "$T/grub.cfg" || { echo "FAIL: GRUB menu not hidden"; exit 1; }
grep -q 'splash' "$T/grub.cfg"   || { echo "FAIL: splash not in kernel cmdline"; exit 1; }
for f in usr/share/sequoia/logo.svg usr/share/sequoia/startup-sound.wav usr/share/sequoia/Hidden-Forest.mp4 \
         usr/share/plymouth/themes/sequoia/logo.png usr/share/plymouth/themes/sequoia/sequoia.script \
         usr/lib/sequoia/startup-sound usr/bin/sequoia-dock usr/share/plasma/plasmoids/org.sequoia.logomenu/metadata.json; do
  unsquashfs -l "$T/fs.squashfs" "$f" >/dev/null 2>&1 && unsquashfs -l "$T/fs.squashfs" | grep -q "squashfs-root/$f$" \
    && echo "ok   $f" || { echo "FAIL: missing in image: $f"; exit 1; }
done
unsquashfs -d "$T/x" -f "$T/fs.squashfs" usr/share/sequoia/logo.svg usr/share/sequoia/startup-sound.wav >/dev/null
cmp "$T/x/usr/share/sequoia/logo.svg" "$(dirname "$0")/../assets/originals/logo.svg" && echo "ok   logo.svg identical to supplied asset"
cmp "$T/x/usr/share/sequoia/startup-sound.wav" "$(dirname "$0")/../assets/originals/startup-sound.wav" && echo "ok   startup sound identical to supplied asset"
echo "VERIFY PASSED (static checks only; boot/audio/UI must be tested in a VM, see docs/TESTING.md)"
