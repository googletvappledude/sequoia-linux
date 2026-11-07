# Sequoia Linux (private, educational)

A Debian 13 "trixie" live/installable distribution with a macOS-Sequoia-inspired desktop on KDE Plasma 6.
See `docs/ARCHITECTURE.md` (design), `docs/STATUS.md` (what works / what is untested / next), `docs/TESTING.md`.

Build: push to a **private** GitHub repo -> Actions -> "Build ISO" -> download artifact `sequoia-linux-iso`.
Local checks (no ISO needed): `bash tests/test_startup_sound.sh && bash tests/test_assets.sh`

Assets in `assets/originals/` are the single source of truth and are copied unmodified into the image at build time.
