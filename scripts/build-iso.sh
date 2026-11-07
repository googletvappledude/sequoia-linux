#!/bin/bash
# Build the ISO. Must run as root inside Debian trixie (CI uses a privileged debian:trixie container).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${WORK:-$ROOT/build}"
apt-get update
apt-get install -y --no-install-recommends live-build debootstrap squashfs-tools xorriso mtools dosfstools \
  grub-pc-bin grub-efi-amd64-bin grub-common ca-certificates debian-archive-keyring
rm -rf "$WORK" && mkdir -p "$WORK"
cp -a "$ROOT/iso/." "$WORK/"
# Supplied assets are copied unmodified from assets/ (single source of truth)
S="$WORK/config/includes.chroot/usr/share/sequoia"; mkdir -p "$S"
cp "$ROOT"/assets/originals/{logo.svg,startup-sound.wav,Hidden-Forest.mp4,San-Francisco-Font.zip} "$S/"
cp "$ROOT/assets/derived/hidden-forest-still.jpg" "$S/wallpaper-still.jpg"
# The dock .deb is produced by the 'components' CI job and dropped in components/out/
mkdir -p "$WORK/config/packages.chroot"
cp "$ROOT"/components/out/*.deb "$WORK/config/packages.chroot/" 2>/dev/null || echo "WARNING: no component .debs found"
cd "$WORK"
chmod +x auto/config config/hooks/normal/*
lb clean --purge 2>/dev/null || true
lb config
lb build 2>&1 | tee "$ROOT/build.log"
ls -lh "$WORK"/*.iso
