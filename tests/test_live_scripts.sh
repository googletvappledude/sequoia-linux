#!/bin/bash
# Tests the live-only autologin and installer-icon scripts.
set -u; cd "$(dirname "$0")/.."; fail=0; L=iso/config/includes.chroot/usr/lib/sequoia
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
chk(){ if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; fail=1; fi; }
SEQUOIA_AUTOLOGIN_FILE="$W/sddm/al.conf" SEQUOIA_LIVE_USER=live sh $L/live-autologin
chk "autologin file written"      "grep -q '^User=live\$' $W/sddm/al.conf && grep -q '^Session=plasma.desktop\$' $W/sddm/al.conf"
mkdir -p "$W/run-live"; cp iso/config/includes.chroot/usr/share/applications/sequoia-install.desktop "$W/l.desktop"
SEQUOIA_LIVE_MARKER="$W/run-live" SEQUOIA_DESKTOP_DIR="$W/Desk" SEQUOIA_LAUNCHER="$W/l.desktop" sh $L/live-installer-icon
chk "installer icon placed on live desktop, executable" "[ -x $W/Desk/sequoia-install.desktop ]"
SEQUOIA_LIVE_MARKER="$W/not-live" SEQUOIA_DESKTOP_DIR="$W/Desk2" SEQUOIA_LAUNCHER="$W/l.desktop" sh $L/live-installer-icon
chk "no icon on an installed system" "[ ! -e $W/Desk2 ]"
chk "no static autologin file in overlay" "[ ! -e iso/config/includes.chroot/etc/sddm.conf.d/20-live-autologin.conf ]"
syn(){ for f in "$@"; do sh_=$(head -1 "$f" | grep -q bash && echo bash || echo sh); $sh_ -n "$f" || return 1; done; }
chk "hooks and scripts syntax (interpreter taken from each shebang)" "syn $L/* iso/config/hooks/normal/*"
exit $fail
