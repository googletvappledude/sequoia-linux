#!/bin/bash
# Tests the .deb packaging logic with a stand-in binary (real binary is compiled in CI).
set -u; cd "$(dirname "$0")/.."; fail=0
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
chk(){ if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; fail=1; fi; }
bash scripts/make-dock-deb.sh /bin/true "$W/out" >/dev/null
D="$W/out/sequoia-dock_0.1.0_amd64.deb"
chk "deb has live-build-compatible filename" "[ -f $D ]"
chk "deb contains /usr/bin/sequoia-dock"      "dpkg-deb -c $D | grep ' ./usr/bin/sequoia-dock\$' >/dev/null"
chk "deb contains XDG autostart entry"        "dpkg-deb -c $D | grep ' ./etc/xdg/autostart/sequoia-dock.desktop\$' >/dev/null"
chk "deb architecture is amd64"               "[ \"\$(dpkg-deb -f $D Architecture)\" = amd64 ]"
chk "deb declares plasma-workspace dependency" "dpkg-deb -f $D Depends | grep -q plasma-workspace"
exit $fail
