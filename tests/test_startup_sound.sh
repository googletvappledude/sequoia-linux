#!/bin/bash
# Verifies one-shot behaviour with a stub player. Exit non-zero on any failure.
set -u
S="$(dirname "$0")/../iso/config/includes.chroot/usr/lib/sequoia/startup-sound"
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
printf '#!/bin/sh\necho "$1" >> %s/plays\n' "$W" > "$W/player"; chmod +x "$W/player"
export SEQUOIA_PLAYER="$W/player" SEQUOIA_SOUND="$(dirname "$0")/../assets/originals/startup-sound.wav" SEQUOIA_STATE_DIR="$W/state" SEQUOIA_CONF="$W/conf" SEQUOIA_BOOT_ID=boot-A
plays(){ [ -f "$W/plays" ] && wc -l < "$W/plays" || echo 0; }
fail=0; chk(){ if [ "$2" = "$3" ]; then echo "PASS $1"; else echo "FAIL $1 (got $2, want $3)"; fail=1; fi; }
"$S" >/dev/null; chk "first run plays"            "$(plays)" 1
"$S" >/dev/null; chk "service restart: no replay" "$(plays)" 1
"$S" >/dev/null; chk "panel restart: no replay"   "$(plays)" 1
( "$S" >/dev/null & "$S" >/dev/null & wait ); chk "concurrent: no replay" "$(plays)" 1
SEQUOIA_BOOT_ID=boot-B "$S" >/dev/null; chk "new boot plays again" "$(plays)" 2
echo "enabled=false" > "$W/conf"; SEQUOIA_BOOT_ID=boot-C "$S" >/dev/null; chk "disabled: silent" "$(plays)" 2
echo "enabled=true" > "$W/conf";  SEQUOIA_BOOT_ID=boot-C "$S" >/dev/null; chk "re-enabled plays"  "$(plays)" 3
# concurrency from cold state
rm -rf "$W/state" "$W/plays"; ( for i in 1 2 3 4 5; do "$S" >/dev/null & done; wait ); chk "5 racing instances play once" "$(plays)" 1
# asset sanity: the supplied file decodes
ffmpeg -v error -i "$SEQUOIA_SOUND" -f null - && echo "PASS wav decodes" || { echo "FAIL wav decode"; fail=1; }
exit $fail
