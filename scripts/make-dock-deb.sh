
#!/bin/bash
# Build the Sequoia Dock Debian package.
# Usage: make-dock-deb.sh <built-binary> <output-directory>

set -euo pipefail

BIN="${1:?Missing path to sequoia-dock binary}"
OUT="${2:?Missing output directory}"
VER="0.1.0"

SRC="$(cd "$(dirname "$0")/.." && pwd)/components/sequoia-dock"

if [ ! -f "$BIN" ]; then
    echo "ERROR: Dock executable not found: $BIN" >&2
    exit 1
fi

if [ ! -f "$SRC/sequoia-dock.desktop" ]; then
    echo "ERROR: sequoia-dock.desktop not found" >&2
    exit 1
fi

T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

P="$T/pkg"

mkdir -p \
    "$P/usr/bin" \
    "$P/etc/xdg/autostart" \
    "$P/DEBIAN" \
    "$OUT"

# Install the dock executable.
install -m 0755 "$BIN" "$P/usr/bin/sequoia-dock"

# Install KDE automatic startup entry.
install -m 0644 \
    "$SRC/sequoia-dock.desktop" \
    "$P/etc/xdg/autostart/sequoia-dock.desktop"

# Detect shared-library dependencies.
SHL=""

if command -v dpkg-shlibdeps >/dev/null 2>&1; then
    mkdir -p "$T/w/debian"

    printf 'Source: sequoia-dock\n\nPackage: sequoia-dock\nArchitecture: any\n' \
        > "$T/w/debian/control"

    SHL="$(
        cd "$T/w" &&
        dpkg-shlibdeps -O -e "$P/usr/bin/sequoia-dock" 2>/dev/null |
        sed -n 's/^shlibs:Depends=//p' || true
    )"
fi

# Runtime dependencies required by the dock.
DEPS="plasma-workspace, qml6-module-qtquick-controls, qml6-module-qtquick-layouts"
if [ -n "$SHL" ]; then
    DEPS="$DEPS, $SHL"
fi

# Package metadata.
cat > "$P/DEBIAN/control" <<CTL
Package: sequoia-dock
Version: $VER
Architecture: amd64
Maintainer: Sequoia Linux <sequoia-linux@localhost>
Section: x11
Priority: optional
Depends: $DEPS
Description: Sequoia Dock
 A floating KDE dock with application launching,
 task management, magnification and LayerShellQt support.
CTL

# Build the Debian package.
dpkg-deb --root-owner-group --build \
    "$P" \
    "$OUT/sequoia-dock_${VER}_amd64.deb"

echo
echo "========================================"
echo " Sequoia Dock package built successfully"
echo "========================================"
echo "Output: $OUT/sequoia-dock_${VER}_amd64.deb"
