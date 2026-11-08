#!/bin/bash
# Tests the boot-time sound service logic with stub aplay/amixer and fake sound cards.
set -u; cd "$(dirname "$0")/.."; S=iso/config/includes.chroot/usr/lib/sequoia/boot-sound; fail=0
W=$(mktemp -d); trap 'rm -rf "$W"' EXIT
chk(){ if [ "$2" = "$3" ]; then echo "PASS $1"; else echo "FAIL $1 (got $2, want $3)"; fail=1; fi; }
printf 'card 0: PCH [HDA Intel PCH], device 0: ALC269 Analog [ALC269 Analog]\ncard 1: HDMI [HDA ATI HDMI], device 3: HDMI 0 [HDMI 0]\n' > "$W/cards"
cat > "$W/aplay" <<STUB
#!/bin/sh
if [ "\$1" = "-l" ]; then [ -f $W/nocards ] && exit 0; cat $W/cards; exit 0; fi
[ -f $W/failplay ] && exit 1
echo "\$*" >> $W/plays
STUB
printf '#!/bin/sh\nexit 0\n' > "$W/amixer"; chmod +x "$W/aplay" "$W/amixer"
export SEQUOIA_APLAY="$W/aplay" SEQUOIA_AMIXER="$W/amixer" SEQUOIA_RUN_DIR="$W/run" SEQUOIA_SYS_CONF="$W/conf" SEQUOIA_WAIT=1 SEQUOIA_SOUND=assets/originals/startup-sound.wav
plays(){ [ -f "$W/plays" ] && wc -l < "$W/plays" || echo 0; }
bash $S >/dev/null;           chk "plays on both cards in parallel" "$(plays)" 2
chk "flag written after success" "$([ -e $W/run/startup-sound.played ] && echo yes)" yes
bash $S >/dev/null;           chk "second run: no replay" "$(plays)" 2
( bash $S >/dev/null & bash $S >/dev/null & wait ); chk "concurrent runs: no replay" "$(plays)" 2
grep -q 'plughw:0,0' "$W/plays" && echo "PASS targets plughw:0,0" || { echo "FAIL device arg"; fail=1; }
rm -rf "$W/run" "$W/plays"; echo "enabled=false" > "$W/conf"; bash $S >/dev/null; chk "disabled: silent" "$(plays)" 0
echo "enabled=true" > "$W/conf"; touch "$W/nocards"; bash $S >/dev/null; chk "no card: silent, no flag" "$(plays)$([ -e $W/run/startup-sound.played ] && echo F)" 0
rm "$W/nocards"; touch "$W/failplay"; bash $S >/dev/null; chk "playback failure: no flag (fallback may try)" "$([ -e $W/run/startup-sound.played ] && echo F || echo none)" none
rm "$W/failplay"; bash $S >/dev/null; chk "retry after failure plays" "$(plays)" 2
# fallback script must stay silent once the boot service has played
SU=iso/config/includes.chroot/usr/lib/sequoia/startup-sound; printf '#!/bin/sh\necho x >> %s/fb\n' "$W" > "$W/pl"; chmod +x "$W/pl"
SEQUOIA_PLAYER="$W/pl" SEQUOIA_STATE_DIR="$W/st" SEQUOIA_CONF="$W/uc" SEQUOIA_BOOT_ID=b1 SEQUOIA_RUN_FLAG="$W/run/startup-sound.played" bash $SU >/dev/null
chk "login fallback silent after boot play" "$([ -f $W/fb ] && echo played || echo silent)" silent
SEQUOIA_PLAYER="$W/pl" SEQUOIA_STATE_DIR="$W/st" SEQUOIA_CONF="$W/uc" SEQUOIA_BOOT_ID=b1 SEQUOIA_RUN_FLAG="$W/nope" bash $SU >/dev/null
chk "login fallback plays if boot play never happened" "$([ -f $W/fb ] && echo played || echo silent)" played
exit $fail
