#!/usr/bin/env bash
#
# AI Ad Lab desktop app installer (curl bootstrap).
#
# Premium members run this from the AI Ad Lab Skool "App" module:
#   curl -fsSL https://raw.githubusercontent.com/the-ai-ad-lab/installer/main/get-app.sh | bash
#
# It verifies your GitHub access, downloads the latest app from the private
# release, installs it to /Applications, and opens it. No quarantine + no
# "Open Anyway", because the download runs through gh (a CLI), not a browser.
#
# The download is gated: the app lives in a PRIVATE repo, so only members of the
# AI Ad Lab GitHub org can pull it. This script is harmless to read — knowing it
# does not grant access.
set -euo pipefail

REPO="${AAL_RELEASES_REPO:-the-ai-ad-lab/ai-ad-lab-app-releases}"
ORG="the-ai-ad-lab"
APP_NAME="AI Ad Lab.app"
INSTALL_DIR="/Applications"

say() { printf '%s\n' "$*"; }
die() { printf '\n%s\n' "$*" >&2; exit 1; }

say ""
say "AI Ad Lab — installing the desktop app…"

[ "$(uname)" = "Darwin" ] || die "This app is macOS only right now."

command -v gh >/dev/null 2>&1 || die "GitHub CLI (gh) isn't installed yet. In Claude Code run /setup first, then run this again."
gh auth status >/dev/null 2>&1 || die "You're not signed in to GitHub. Run:  gh auth login   then run this again."

WHO="$(gh api user --jq .login 2>/dev/null || echo you)"

if ! gh api "repos/${REPO}/releases/latest" >/dev/null 2>&1; then
  die "${WHO}, your GitHub account doesn't have access to the AI Ad Lab app yet.
You need to be added to the ${ORG} organization. Ask your AI Ad Lab admin, then run this again."
fi
say "Access verified for ${WHO}."

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

say "Downloading the latest version…"
gh release download --repo "$REPO" --pattern '*mac.zip' --dir "$TMP" --clobber >/dev/null 2>&1 \
  || die "Couldn't download the app. Your GitHub token may need the 'repo' scope — run:  gh auth login --scopes repo   then run this again."

ZIP="$(ls "$TMP"/*.zip 2>/dev/null | head -1 || true)"
{ [ -n "${ZIP:-}" ] && [ -f "$ZIP" ]; } || die "The download didn't contain the app."

say "Installing…"
mkdir -p "$TMP/u"
ditto -x -k "$ZIP" "$TMP/u"
SRC="$(find "$TMP/u" -maxdepth 2 -name '*.app' -type d | head -1 || true)"
{ [ -n "${SRC:-}" ] && [ -d "$SRC" ]; } || die "The download didn't contain an app bundle."

DEST="$INSTALL_DIR/$APP_NAME"
[ -d "$DEST" ] && rm -rf "$DEST"
ditto "$SRC" "$DEST"
# CLI download = no quarantine; re-sign locally so it can't show "damaged".
xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true
codesign --force --deep --sign - "$DEST" >/dev/null 2>&1 || true

say "Opening AI Ad Lab…"
open "$DEST" 2>/dev/null || true
say ""
say "Done. AI Ad Lab is in your Applications folder — launch it anytime from there or Spotlight."
