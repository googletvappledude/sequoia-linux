#!/bin/bash
# Package the compiled dock as sequoia-dock_<ver>_amd64.deb (name format required by live-build).
# usage: make-dock-deb.sh <path-to-built-sequoia-dock-binary> <output-dir>
set -euo pipefail
BIN="${1:?path to sequoia-dock binary}"; OUT="${2:?output dir}"; VER="0.1.0"
SRC="$(cd "$(dirname "$0")/.." && pwd)/components/sequoia-dock"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
P="$T/pkg"; mkdir -p "$P/usr/bin" "$P/etc/xdg/autostart" "$P/DEBIAN" "$OUT"
install -m 0755 "$BIN" "$P/usr/bin/sequoia-dock"
install -m 0644 "$SRC/sequoia-dock.desktop" "$P/etc/xdg/autostart/sequoia-dock.desktop"
# Compute shared-library dependencies (needs dpkg-dev); fall back to the static list if unavailable
SHL=""
if command -v dpkg-shlibdeps >/dev/null; then
  mkdir -p "$T/w/debian"; printf 'Source: sequoia-dock\n\nPackage: sequoia-dock\nArchitecture: any\n' > "$T/w/debian/control"
  SHL=$(cd "$T/w" && dpkg-shlibdeps -O -e "$P/usr/bin/sequoia-dock" 2>/dev/null | sed -n 's/^shlibs:Depends=//p' || true)
fi
DEPS="plasma-workspace, qml6-module-qtquick-controls, qml6-module-qtquick-layouts${SHL:+, $SHL}"
cat > "$P/DEBIAN/control" <<CTL
Package: sequoia-dock
Version: $VER
Architecture: amd64
Maintainer: Sequoia Linux <sequoia-linux@localhost>
Section: x11
Priority: optional
Depends: $DEPS
Description: Sequoia Dock (layer-shell dock with magnification)
CTL
dpkg-deb --root-owner-group --build "$P" "$OUT/sequoia-dock_${VER}_amd64.deb" >/dev/null
echo "built $OUT/sequoia-dock_${VER}_amd64.deb"
