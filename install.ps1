# Public bootstrap installer for The AI Ad Lab.
# Members run this on Windows in PowerShell:
#   irm https://raw.githubusercontent.com/the-ai-ad-lab/installer/main/install.ps1 | iex
#
# Installs Claude Code, GitHub CLI, authenticates, verifies access to
# the private members repo, then installs The AI Ad Lab plugin at user scope.
# Idempotent. Safe to rerun.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# ----- Logging setup -----

$LogDir  = Join-Path $HOME 'AI-Ad-Lab\_meta\.state'
$null    = New-Item -ItemType Directory -Force -Path $LogDir
$LogFile = Join-Path $LogDir 'bootstrap-install.log'

function Write-Log {
  param([string]$Message)
  $stamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
  $line  = "[$stamp] $Message"
  Write-Host $line
  Add-Content -Path $LogFile -Value $line
}

function Write-Step {
  param([int]$Num, [string]$Title)
  Write-Host ''
  Write-Host "[$Num/7] $Title"
  Add-Content -Path $LogFile -Value "[$Num/7] $Title"
}

function Stop-WithFix {
  param([string]$ErrorMsg, [string]$FixMsg)
  Write-Host ''
  Write-Host "ERROR: $ErrorMsg" -ForegroundColor Red
  Write-Host "Fix: $FixMsg"
  exit 1
}

function Refresh-Path {
  $userPath    = [System.Environment]::GetEnvironmentVariable('Path', 'User')
  $machinePath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
  $env:Path    = "$machinePath;$userPath"
}

# ----- OS detection -----

if ($PSVersionTable.Platform -and $PSVersionTable.Platform -ne 'Win32NT') {
  Stop-WithFix 'This installer is for Windows only.' 'On macOS, use the install.sh one liner from the README.'
}

Write-Log 'Starting The AI Ad Lab bootstrap install on Windows.'

# ----- [1/7] Claude Code -----

Write-Step 1 'Checking for Claude Code...'

$claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
if (-not $claudeCmd) {
  Write-Log 'Claude Code CLI not found. Installing via winget.'
  $winget = Get-Command winget -ErrorAction SilentlyContinue
  if (-not $winget) {
    Stop-WithFix 'winget is required to install Claude Code.' 'Install App Installer from the Microsoft Store, then rerun this script.'
  }
  & winget install --silent --accept-package-agreements --accept-source-agreements Anthropic.ClaudeCode
  if ($LASTEXITCODE -ne 0) {
    Stop-WithFix "winget install of Claude Code failed (exit $LASTEXITCODE)." 'Try installing manually from https://claude.ai/download then rerun.'
  }
  Refresh-Path
  $claudeCmd = Get-Command claude -ErrorAction SilentlyContinue
  if (-not $claudeCmd) {
    Stop-WithFix 'Claude Code installed but binary is not on PATH.' 'Open a fresh PowerShell window and rerun this script.'
  }
  Write-Log "Claude Code installed: $(& claude --version)"
} else {
  Write-Log "Claude Code already installed: $(& claude --version)"
}

# ----- [2/7] GitHub CLI -----

Write-Step 2 'Checking for GitHub CLI...'

$ghCmd = Get-Command gh -ErrorAction SilentlyContinue
if (-not $ghCmd) {
  Write-Log 'GitHub CLI not found. Installing via winget.'
  $winget = Get-Command winget -ErrorAction SilentlyContinue
  if (-not $winget) {
    Stop-WithFix 'winget is required to install GitHub CLI.' 'Install App Installer from the Microsoft Store, then rerun this script.'
  }
  & winget install --silent --accept-package-agreements --accept-source-agreements GitHub.cli
  if ($LASTEXITCODE -ne 0) {
    Stop-WithFix "winget install of GitHub CLI failed (exit $LASTEXITCODE)." 'Try installing manually from https://cli.github.com/ then rerun.'
  }
  Refresh-Path
  $ghCmd = Get-Command gh -ErrorAction SilentlyContinue
  if (-not $ghCmd) {
    Stop-WithFix 'GitHub CLI installed but binary is not on PATH.' 'Open a fresh PowerShell window and rerun this script.'
  }
  Write-Log "GitHub CLI installed: $(& gh --version | Select-Object -First 1)"
} else {
  Write-Log "GitHub CLI already installed: $(& gh --version | Select-Object -First 1)"
}

# ----- [3/7] GitHub authentication -----

Write-Step 3 'Checking GitHub authentication...'

& gh auth status 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Log 'Not authenticated with GitHub. Starting interactive login.'
  Write-Host ''
  Write-Host 'GitHub will open a device code in your browser. Approve it to authenticate.'
  Write-Host ''
  & gh auth login --hostname github.com --git-protocol https --web
  if ($LASTEXITCODE -ne 0) {
    Stop-WithFix 'GitHub authentication did not complete.' 'Rerun this installer and complete the device code prompt in your browser.'
  }
  Write-Log 'GitHub authentication complete.'
} else {
  $loginName = & gh api user --jq .login
  Write-Log "Already authenticated with GitHub as $loginName."
}

# ----- [4/7] Verify access to the members repo -----

Write-Step 4 'Verifying access to the members repo...'

& gh api repos/the-ai-ad-lab/ai-ad-lab 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
  Write-Host ''
  Write-Host '============================================================'
  Write-Host 'You do not have access to the-ai-ad-lab/ai-ad-lab yet.'
  Write-Host ''
  Write-Host 'This is a private repo for active Skool community members.'
  Write-Host 'Your Skool subscription should add you to the GitHub team'
  Write-Host 'within 24 hours. If it has been longer, post your GitHub'
  Write-Host 'username in The AI Ad Lab Skool community and we will add'
  Write-Host 'you manually.'
  Write-Host ''
  Write-Host 'Once you have access, rerun this installer:'
  Write-Host '  irm https://raw.githubusercontent.com/the-ai-ad-lab/installer/main/install.ps1 | iex'
  Write-Host '============================================================'
  Write-Host ''
  exit 0
}
Write-Log 'Access to the-ai-ad-lab/ai-ad-lab confirmed.'

# ----- [5/7] Add the marketplace -----

Write-Step 5 'Adding The AI Ad Lab marketplace...'

& claude plugin marketplace add the-ai-ad-lab/ai-ad-lab
if ($LASTEXITCODE -ne 0) {
  Stop-WithFix 'Marketplace add failed.' 'Run claude plugin marketplace add the-ai-ad-lab/ai-ad-lab manually to see the full error.'
}
Write-Log 'Marketplace added.'

# ----- [6/7] Install the plugin -----

Write-Step 6 'Installing The AI Ad Lab plugin...'

& claude plugin install 'ai-ad-lab@ai-ad-lab' --scope user
if ($LASTEXITCODE -ne 0) {
  Stop-WithFix 'Plugin install failed.' 'Run claude plugin install ai-ad-lab@ai-ad-lab --scope user manually to see the full error.'
}
Write-Log 'Plugin installed.'

# ----- [7/7] Done -----

Write-Step 7 'Done.'
Write-Log 'Bootstrap install complete.'

@'

============================================================
The AI Ad Lab plugin installed.

Open Claude Code and run /ai-ad-lab:setup to finish configuration.

After /ai-ad-lab:setup, run /ai-ad-lab:welcome to see your skills
and start your first workflow.
============================================================

'@ | Write-Host

exit 0
