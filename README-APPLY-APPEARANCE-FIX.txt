SEQUOIA LINUX — APPEARANCE FIX (WINDOW DECORATION + ICON THEME)

This patch is designed to be overlaid onto the existing sequoia-linux-git clone.
It also carries the Update 15 installer files so the password dictionary fix is
kept in the next test ISO.

IMPORTANT TEST PLAN
1. Let the current GitHub Actions run finish and download its ISO artifact first.
   Keep that ISO as TEST 1 (the current baseline build).
2. Apply this ZIP to ~/Downloads/sequoia-linux-git.
3. Run the three tests listed below. Only commit/push if all pass.
4. GitHub Actions will create TEST 2, which includes the decoration and icon theme.

APPLY
  cd ~/Downloads/sequoia-linux-git
  unzip -o ~/Downloads/sequoia-appearance-fix.zip

TEST
  bash tests/test_decoration_package.sh
  bash tests/test_icon_theme.sh
  bash tests/test_installer_config.sh

EXPECTED: all tests print PASS.

COMMIT AND PUSH
  git add -A
  git commit -m "Add Sequoia macOS window decoration and icon theme"
  git push origin main

Then open https://github.com/googletvappledude/sequoia-linux/actions
and wait for the new Build ISO run. The components job now builds two required
Debian packages: Sierra Breeze Enhanced (KWin window decoration) and WhiteSur
icons packaged as the Sequoia icon theme. The ISO verifier fails if either is
missing or not selected in the default Plasma configuration.

The upstream decoration and icon projects are fetched by GitHub Actions during
build. Therefore the build needs internet access. Actual appearance and boot
behaviour still require VM testing; automated checks cannot prove the desktop
looks correct.
