# Testing
Automated (CI): `tests/test_startup_sound.sh`, `tests/test_assets.sh`, qmllint, dock compile, `scripts/verify-iso.sh`.
Manual in a VM (QEMU/virt-manager, UEFI + BIOS): boot is black with centred logo only; sound plays once, not on `systemctl --user restart plasma-plasmashell`; dock magnifies/minimises; settings persist after reboot.
Record results in STATUS.md only after they were actually observed.
