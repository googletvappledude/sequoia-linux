#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ -x "$ROOT/scripts/build-icon-theme.sh" ]
grep -q 'WhiteSur-icon-theme.git' "$ROOT/scripts/build-icon-theme.sh"
grep -q '^IconTheme=Sequoia' "$ROOT/iso/config/includes.chroot/etc/skel/.config/kdeglobals"
grep -q '^Theme=Sequoia' "$ROOT/iso/config/includes.chroot/usr/share/sequoia/kpackages/look-and-feel/org.sequoia.desktop/contents/defaults"
echo 'PASS icon theme build script and Plasma defaults'
