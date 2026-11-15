#!/usr/bin/env bash
set -euo pipefail
OUT="\${1:-components/out}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
SRC="$WORK/SierraBreezeEnhanced"
PKG="$WORK/pkg"
mkdir -p "$OUT" "$PKG/DEBIAN" "$PKG/usr/share/doc/sequoia-sierra-breeze-enhanced"
git clone --depth 1 https://github.com/kupiqu/SierraBreezeEnhanced.git "$SRC"
python3 - "$SRC/CMakeLists.txt" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
source = path.read_text()
old = "find_package(Qt6 REQUIRED COMPONENTS Core5Compat GuiPrivate)"
new = """find_package(Qt6 REQUIRED COMPONENTS Core5Compat)
if(NOT TARGET Qt6::GuiPrivate)
  find_path(QT6_GUI_PRIVATE_INCLUDE_ROOT
    NAMES QtGui/private/qtx11extras_p.h
    PATHS "/usr/include/\${CMAKE_LIBRARY_ARCHITECTURE}/qt6/QtGui/\${Qt6_VERSION}"
    NO_DEFAULT_PATH)
  if(NOT QT6_GUI_PRIVATE_INCLUDE_ROOT)
    message(FATAL_ERROR "Qt GUI private headers are missing. Install qt6-base-private-dev.")
  endif()
  add_library(Qt6::GuiPrivate INTERFACE IMPORTED)
  set_target_properties(Qt6::GuiPrivate PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "\${QT6_GUI_PRIVATE_INCLUDE_ROOT}"
    INTERFACE_LINK_LIBRARIES Qt6::Gui)
endif()"""
if old not in source:
    raise SystemExit("Expected Qt6 GuiPrivate find_package line was not found")
path.write_text(source.replace(old, new, 1))
PY
cmake -S "$SRC" -B "$WORK/build" -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DKDE_INSTALL_LIBDIR=lib -DKDE_INSTALL_USE_QT_SYS_PATHS=ON -DBUILD_TESTING=OFF
cmake --build "$WORK/build" --parallel "$(nproc)"
DESTDIR="$PKG" cmake --install "$WORK/build"
PLUGIN="$(find "$PKG/usr" -type f -name 'sierrabreezeenhanced.so' -print -quit)"
[ -n "$PLUGIN" ] || { echo "ERROR: decoration plugin shared object is missing" >&2; exit 1; }
[ -s "$SRC/sierrabreezeenhanced.json" ] || { echo "ERROR: upstream plugin metadata is missing" >&2; exit 1; }
install -m 0644 "$SRC/sierrabreezeenhanced.json" "$(dirname "$PLUGIN")/sierrabreezeenhanced.json"
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
dpkg-deb --contents "$OUT/sequoia-sierra-breeze-enhanced_1.0_amd64.deb" | grep -E 'org\.kde\.kdecoration3|sierrabreezeenhanced\.json' >/dev/null
echo "Built $OUT/sequoia-sierra-breeze-enhanced_1.0_amd64.deb"
