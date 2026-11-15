#!/usr/bin/env bash
# Package the WhiteSur macOS-inspired icon set under the Sequoia theme name.
set -euo pipefail
OUT="${1:-components/out}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
SRC="$WORK/WhiteSur-icon-theme"
PKG="$WORK/pkg"
mkdir -p "$OUT" "$PKG/DEBIAN" "$PKG/usr/share/icons" "$PKG/usr/share/doc/sequoia-icon-theme"

git clone --depth 1 https://github.com/vinceliuice/WhiteSur-icon-theme.git "$SRC"
# -a selects the alternative macOS-like application icons. WhiteSur calls its base colour variant 'default' (the installer help's 'blue' label is only its fallback description).
bash "$SRC/install.sh" --dest "$PKG/usr/share/icons" --name Sequoia --theme default --alternative

[ -s "$PKG/usr/share/icons/Sequoia/index.theme" ] || {
  echo "ERROR: WhiteSur installer did not create Sequoia/index.theme" >&2
  exit 1
}
cp "$SRC/COPYING" "$PKG/usr/share/doc/sequoia-icon-theme/copyright"
cat > "$PKG/DEBIAN/control" <<'CONTROL'
Package: sequoia-icon-theme
Version: 1.0
Section: x11
Priority: optional
Architecture: all
Maintainer: Sequoia Linux <maintainers@invalid.example>
Description: Sequoia macOS-inspired icon theme
 WhiteSur icon artwork installed under the Sequoia theme name.
CONTROL

dpkg-deb --build --root-owner-group "$PKG" "$OUT/sequoia-icon-theme_1.0_all.deb" >/dev/null
dpkg-deb --contents "$OUT/sequoia-icon-theme_1.0_all.deb" | grep -F 'usr/share/icons/Sequoia/index.theme' >/dev/null
echo "Built $OUT/sequoia-icon-theme_1.0_all.deb"
