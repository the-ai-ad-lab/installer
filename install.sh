#!/usr/bin/env bash
# Public bootstrap installer for The AI Ad Lab.
# Members run this on macOS:
#   curl -fsSL https://raw.githubusercontent.com/the-ai-ad-lab/installer/main/install.sh | bash
#
# Installs Claude Code, GitHub CLI, authenticates, verifies access to
# the private members repo, then installs The AI Ad Lab plugin at user scope.
# Idempotent. Safe to rerun.

set -euo pipefail

# ----- Logging setup -----

LOG_DIR="$HOME/AI-Ad-Lab/_meta/.state"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/bootstrap-install.log"

log() {
  printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" | tee -a "$LOG_FILE"
}

step() {
  printf '\n[%s/7] %s\n' "$1" "$2" | tee -a "$LOG_FILE"
}

fail() {
  printf '\nERROR: %s\n' "$1" >&2
  printf 'Fix: %s\n' "$2" >&2
  exit 1
}

# ----- OS detection -----

if [ "$(uname -s)" != "Darwin" ]; then
  fail "This installer is for macOS only." "On Windows, use the install.ps1 one liner from the README."
fi

log "Starting The AI Ad Lab bootstrap install on macOS."

# ----- [1/7] Claude Code -----

step 1 "Checking for Claude Code..."

if ! command -v claude >/dev/null 2>&1; then
  log "Claude Code CLI not found. Installing via the official installer."
  if ! command -v curl >/dev/null 2>&1; then
    fail "curl is required to install Claude Code." "Install Xcode Command Line Tools with: xcode-select --install"
  fi
  curl -fsSL https://claude.ai/install.sh | bash
  if ! command -v claude >/dev/null 2>&1; then
    if [ -x "$HOME/.local/bin/claude" ]; then
      export PATH="$HOME/.local/bin:$PATH"
    elif [ -x "/opt/homebrew/bin/claude" ]; then
      export PATH="/opt/homebrew/bin:$PATH"
    fi
  fi
  if ! command -v claude >/dev/null 2>&1; then
    fail "Claude Code installed but the binary is not on PATH." "Open a fresh terminal and rerun this script."
  fi
  log "Claude Code installed: $(claude --version 2>&1 | head -n 1)"
else
  log "Claude Code already installed: $(claude --version 2>&1 | head -n 1)"
fi

# ----- [2/7] GitHub CLI -----

step 2 "Checking for GitHub CLI..."

if ! command -v gh >/dev/null 2>&1; then
  log "GitHub CLI not found. Installing via Homebrew."
  if ! command -v brew >/dev/null 2>&1; then
    log "Homebrew not found. Installing Homebrew first."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [ -x "/opt/homebrew/bin/brew" ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -x "/usr/local/bin/brew" ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  fi
  brew install gh
  if ! command -v gh >/dev/null 2>&1; then
    fail "GitHub CLI installed but the binary is not on PATH." "Open a fresh terminal and rerun this script."
  fi
  log "GitHub CLI installed: $(gh --version | head -n 1)"
else
  log "GitHub CLI already installed: $(gh --version | head -n 1)"
fi

# ----- [3/7] GitHub authentication -----

step 3 "Checking GitHub authentication..."

if ! gh auth status >/dev/null 2>&1; then
  log "Not authenticated with GitHub. Starting interactive login."
  printf '\nGitHub will open a device code in your browser. Approve it to authenticate.\n\n'
  gh auth login --hostname github.com --git-protocol https --web || \
    fail "GitHub authentication did not complete." "Rerun this installer and complete the device code prompt in your browser."
  log "GitHub authentication complete."
else
  log "Already authenticated with GitHub as $(gh api user --jq .login)."
fi

# ----- [4/7] Verify access to the members repo -----

step 4 "Verifying access to the members repo..."

if ! gh api repos/the-ai-ad-lab/ai-ad-lab >/dev/null 2>&1; then
  printf '\n============================================================\n'
  printf 'You do not have access to the-ai-ad-lab/ai-ad-lab yet.\n\n'
  printf 'This is a private repo for active Skool community members.\n'
  printf 'Your Skool subscription should add you to the GitHub team\n'
  printf 'within 24 hours. If it has been longer, post your GitHub\n'
  printf 'username in The AI Ad Lab Skool community and we will add\n'
  printf 'you manually.\n'
  printf '\nOnce you have access, rerun this installer:\n'
  printf '  curl -fsSL https://raw.githubusercontent.com/the-ai-ad-lab/installer/main/install.sh | bash\n'
  printf '============================================================\n\n'
  exit 0
fi
log "Access to the-ai-ad-lab/ai-ad-lab confirmed."

# ----- [5/7] Add the marketplace -----

step 5 "Adding The AI Ad Lab marketplace..."

claude plugin marketplace add the-ai-ad-lab/ai-ad-lab || \
  fail "Marketplace add failed." "Run claude plugin marketplace add the-ai-ad-lab/ai-ad-lab manually to see the full error."
log "Marketplace added."

# ----- [6/7] Install the plugin -----

step 6 "Installing The AI Ad Lab plugin..."

claude plugin install ai-ad-lab@ai-ad-lab --scope user || \
  fail "Plugin install failed." "Run claude plugin install ai-ad-lab@ai-ad-lab --scope user manually to see the full error."
log "Plugin installed."

# ----- [7/7] Done -----

step 7 "Done."
log "Bootstrap install complete."

cat <<'EOF'

============================================================
The AI Ad Lab plugin installed.

Open Claude Code and run /ai-ad-lab:setup to finish configuration.

After /ai-ad-lab:setup, run /ai-ad-lab:welcome to see your skills
and start your first workflow.
============================================================

EOF

exit 0
