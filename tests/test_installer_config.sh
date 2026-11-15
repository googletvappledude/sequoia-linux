#!/bin/bash
# Tests the installer hook against a temporary root with a fake Calamares config.
set -u; cd "$(dirname "$0")/.."; fail=0; W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
chk(){ if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; fail=1; fi; }
mkdir -p "$W/etc/calamares/modules"
printf -- '---\nusername: user\n' > "$W/etc/calamares/modules/removeuser.conf"
printf -- '---\nallowWeakPasswords: false\nallowWeakPasswordsDefault: false\ndoAutologin: false\n' > "$W/etc/calamares/modules/users.conf"
printf -- '---\nenableLuksAutomatedPartitioning: true\n' > "$W/etc/calamares/modules/partition.conf"
SEQUOIA_ROOT="$W" sh iso/config/hooks/normal/0400-installer.hook.chroot >/dev/null 2>&1
chk "live user set for removal"        "grep -q '^username: live\$' $W/etc/calamares/modules/removeuser.conf"
chk "weak passwords allowed (checkbox)" "grep -q '^allowWeakPasswords: true\$' $W/etc/calamares/modules/users.conf && [ \$(grep -c '^allowWeakPasswords:' $W/etc/calamares/modules/users.conf) = 1 ]"
chk "other users.conf settings kept"   "grep -q '^doAutologin: false\$' $W/etc/calamares/modules/users.conf"
chk "LUKS disabled, no duplicate key"  "grep -q '^enableLuksAutomatedPartitioning: false\$' $W/etc/calamares/modules/partition.conf && [ \$(grep -c '^enableLuksAutomatedPartitioning' $W/etc/calamares/modules/partition.conf) = 1 ]"
chk "installed GRUB config has splash" "grep -q 'splash' $W/etc/default/grub"
chk "dictionary packages in the image" "grep -qx cracklib-runtime iso/config/package-lists/base.list.chroot && grep -qx wamerican iso/config/package-lists/base.list.chroot"
exit $fail
