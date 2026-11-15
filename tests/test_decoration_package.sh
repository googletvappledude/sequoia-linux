#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ -x "$ROOT/scripts/build-decoration.sh" ]
grep -q 'SierraBreezeEnhanced.git' "$ROOT/scripts/build-decoration.sh"
grep -q 'org.kde.sierrabreezeenhanced' "$ROOT/iso/config/includes.chroot/etc/skel/.config/kwinrc"
grep -q '^ButtonsOnLeft=XIA' "$ROOT/iso/config/includes.chroot/etc/skel/.config/kwinrc"
grep -q '^ButtonStyle=macSierra' "$ROOT/iso/config/includes.chroot/etc/skel/.config/sierrabreezeenhancedrc"
echo 'PASS decoration build script and Plasma defaults'
