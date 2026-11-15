#!/usr/bin/env bash
# Build Sierra Breeze Enhanced (macOS-style KWin window buttons) as a Debian package.
set -euo pipefail
OUT="${1:-components/out}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
SRC="$WORK/SierraBreezeEnhanced"
PKG="$WORK/pkg"
mkdir -p "$OUT" "$PKG/DEBIAN" "$PKG/usr/share/doc/sequoia-sierra-breeze-enhanced"

# Sierra Breeze Enhanced is a Plasma 6.3+ KDecoration3 plugin.
git clone --depth 1 https://github.com/kupiqu/SierraBreezeEnhanced.git "$SRC"
cmake -S "$SRC" -B "$WORK/build" \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DCMAKE_BUILD_TYPE=Release \
  -DKDE_INSTALL_LIBDIR=lib \
  -DKDE_INSTALL_USE_QT_SYS_PATHS=ON \
  -DBUILD_TESTING=OFF
cmake --build "$WORK/build" --parallel "$(nproc)"
DESTDIR="$PKG" cmake --install "$WORK/build"

if ! find "$PKG/usr" -type f -name '*.so' | grep -q .; then
  echo "ERROR: decoration build installed no shared plugin" >&2
  exit 1
fi
if ! find "$PKG/usr" -type f -name 'sierrabreezeenhanced.json' | grep -q .; then
  echo "ERROR: Sierra Breeze Enhanced plugin metadata is missing" >&2
  exit 1
fi
cp "$SRC/LICENSE" "$PKG/usr/share/doc/sequoia-sierra-breeze-enhanced/copyright"
cat > "$PKG/DEBIAN/control" <<'CONTROL'
Package: sequoia-sierra-breeze-enhanced
Version: 1.0
Section: kde
Priority: optional
Architecture: amd64
Maintainer: Sequoia Linux <maintainers@invalid.example>
Description: Sierra Breeze Enhanced KWin window decoration for Sequoia Linux
 Provides macOS-inspired window-button styles and configurable titlebars for KDE Plasma 6.
CONTROL

dpkg-deb --build --root-owner-group "$PKG" "$OUT/sequoia-sierra-breeze-enhanced_1.0_amd64.deb" >/dev/null
# Validate the package before uploading it as a CI artifact.
dpkg-deb --contents "$OUT/sequoia-sierra-breeze-enhanced_1.0_amd64.deb" | grep -E 'org\.kde\.kdecoration3|sierrabreezeenhanced\.json' >/dev/null
echo "Built $OUT/sequoia-sierra-breeze-enhanced_1.0_amd64.deb"
