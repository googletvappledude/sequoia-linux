#!/bin/bash
# Static repo checks runnable anywhere.
set -u; cd "$(dirname "$0")/.."; fail=0
chk(){ if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; fail=1; fi; }
I=iso/config/includes.chroot/usr/share/sequoia
chk "no duplicate asset copies in overlay" "[ ! -e $I/logo.svg ] && [ ! -e $I/startup-sound.wav ]"
chk "build script copies supplied assets" "grep -q 'assets/originals/{logo.svg,startup-sound.wav' scripts/build-iso.sh"
chk "plymouth script: black background"      "grep -q 'SetBackgroundTopColor(0.0, 0.0, 0.0)' iso/config/includes.chroot/usr/share/plymouth/themes/sequoia/sequoia.script"
chk "plymouth script: no text/progress APIs" "! grep -qE 'Plymouth\\.Set(Message|Boot|Display)|Text\\(|Progress' iso/config/includes.chroot/usr/share/plymouth/themes/sequoia/sequoia.script"
chk "all hooks executable"                   "[ -z \"\$(find iso/config/hooks -type f ! -perm -u+x)\" ]"
chk "json metadata valid"                    "for f in \$(find iso -name metadata.json); do python3 -m json.tool \$f >/dev/null || exit 1; done"
chk "workflow yaml valid"                    "python3 -c 'import yaml,sys;yaml.safe_load(open(\".github/workflows/build-iso.yml\"))'"
chk "shell syntax"                           "for f in scripts/*.sh tests/*.sh iso/auto/config iso/config/hooks/normal/*; do bash -n \$f || exit 1; done"
exit $fail
