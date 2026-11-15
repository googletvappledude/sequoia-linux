#!/bin/bash
# Tests the installer hook against a temporary root with a fake Calamares config.
set -euo pipefail
cd "$(dirname "$0")/.."
W=$(mktemp -d)
trap 'rm -rf "$W"' EXIT
mkdir -p "$W/etc/calamares/modules"
printf -- '---\nusername: user\n' > "$W/etc/calamares/modules/removeuser.conf"
printf -- '---\nallowWeakPasswords: false\nallowWeakPasswordsDefault: false\ndoAutologin: false\n' > "$W/etc/calamares/modules/users.conf"
printf -- '---\nenableLuksAutomatedPartitioning: true\n' > "$W/etc/calamares/modules/partition.conf"
cat > "$W/etc/calamares/settings.conf" <<'SETTINGS'
sequence:
- exec:
    - users
    - bootloader
    - umount
SETTINGS
SEQUOIA_ROOT="$W" sh iso/config/hooks/normal/0400-installer.hook.chroot >/dev/null
grep -Fqx 'username: live' "$W/etc/calamares/modules/removeuser.conf"
echo "PASS live user set for removal"
grep -Eq '^[[:space:]]*-[[:space:]]*removeuser[[:space:]]*$' "$W/etc/calamares/settings.conf"
echo "PASS removeuser job enabled in sequence"
grep -Fqx 'allowWeakPasswords: true' "$W/etc/calamares/modules/users.conf"
[ "$(grep -Fc 'allowWeakPasswords:' "$W/etc/calamares/modules/users.conf")" = 1 ]
echo "PASS weak passwords allowed (checkbox)"
grep -Fqx 'doAutologin: false' "$W/etc/calamares/modules/users.conf"
echo "PASS other users.conf settings kept"
grep -Fqx 'enableLuksAutomatedPartitioning: false' "$W/etc/calamares/modules/partition.conf"
[ "$(grep -Fc 'enableLuksAutomatedPartitioning:' "$W/etc/calamares/modules/partition.conf")" = 1 ]
echo "PASS LUKS disabled, no duplicate key"
grep -q 'splash' "$W/etc/default/grub"
echo "PASS installed GRUB config has splash"
grep -qx cracklib-runtime iso/config/package-lists/base.list.chroot
grep -qx wamerican iso/config/package-lists/base.list.chroot
echo "PASS dictionary packages in the image"
