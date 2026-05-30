# Public bootstrap installer for AI Ad Lab on Windows.
# Members run this in PowerShell:
#   irm https://raw.githubusercontent.com/the-ai-ad-lab/installer/main/install.ps1 | iex
#
# Installs the official Claude Code native CLI from Anthropic, puts it on PATH,
# then adds AI Ad Lab marketplace and installs the plugin. Idempotent.

$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------

function Write-Step {
    param([string]$Title)
    Write-Host ''
    Write-Host ">>> $Title" -ForegroundColor Cyan
    Write-Host ''
}

function Write-Info {
    param([string]$Message)
    Write-Host "    $Message"
}

function Write-Ok {
    param([string]$Message)
    Write-Host "    $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "    $Message" -ForegroundColor Yellow
}

function Stop-Phase {
    param([string]$Phase, [string]$Message, [string]$Hint)
    Write-Host ''
    Write-Host "Something went wrong in $Phase." -ForegroundColor Red
    Write-Host ''
    Write-Host $Message -ForegroundColor Red
    if ($Hint) {
        Write-Host ''
        Write-Host "What to do next:" -ForegroundColor Yellow
        Write-Host $Hint
    }
    Write-Host ''
    exit 1
}

# ---------------------------------------------------------------------------
# PHASE A. Banner and pre-flight summary
# ---------------------------------------------------------------------------

try {
    Write-Step 'PHASE A. Welcome'

    Write-Host '    ============================================================'
    Write-Host '    Welcome to AI Ad Lab installer for Windows.'
    Write-Host '    ============================================================'
    Write-Host ''
    Write-Info 'This will install Claude Code, then install AI Ad Lab plugin.'
    Write-Info 'Total time: about 3 minutes.'
    Write-Info ''
    Write-Info 'You may see one Windows security prompt during install. Click yes if you do.'
    Write-Info ''
    Write-Info 'If you have the Claude Desktop app installed, you may need to disable'
    Write-Info 'one setting. The script will tell you exactly what to do.'
    Write-Host ''
    Write-Info 'Starting in 5 seconds. Read the message above first.'

    for ($i = 5; $i -ge 1; $i--) {
        Write-Host "    $i..."
        Start-Sleep -Seconds 1
    }
} catch {
    Stop-Phase 'PHASE A (welcome banner)' `
        "The script could not show the welcome banner." `
        "Close this window, open a fresh PowerShell window, and try again."
}

# ---------------------------------------------------------------------------
# PHASE B. PowerShell ExecutionPolicy check and fix
# ---------------------------------------------------------------------------

try {
    Write-Step 'PHASE B. Checking PowerShell settings'

    $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
    Write-Info "Current PowerShell policy for your user: $currentPolicy"

    $needsFix = @('Restricted', 'Undefined', 'AllSigned') -contains [string]$currentPolicy
    if ($needsFix) {
        Write-Info 'Updating policy so trusted scripts can run for your user only.'
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
        $newPolicy = Get-ExecutionPolicy -Scope CurrentUser
        Write-Ok "Policy updated to: $newPolicy"
    } else {
        Write-Ok 'Policy is already set correctly. No change needed.'
    }
} catch {
    Stop-Phase 'PHASE B (PowerShell settings)' `
        "We could not update your PowerShell policy automatically." `
        @"
Open a new PowerShell window and paste this single line:

    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force

Then run the install command again.

If that still fails, the official guide is at:
https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy
"@
}

# ---------------------------------------------------------------------------
# PHASE C. Claude Desktop App Execution Alias detection
# ---------------------------------------------------------------------------

try {
    Write-Step 'PHASE C. Checking for Claude Desktop conflict'

    $aliasPath = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\Claude.exe'

    if (Test-Path $aliasPath) {
        Write-Host ''
        Write-Warn '============================================================'
        Write-Warn 'WARNING. Claude Desktop App Execution Alias is enabled.'
        Write-Warn 'This will collide with the Claude Code CLI.'
        Write-Warn '============================================================'
        Write-Host ''
        Write-Info 'Please do this now:'
        Write-Info ''
        Write-Info "1. Press Windows key, type 'app execution aliases', open the result"
        Write-Info "2. Find 'Claude.exe' in the list"
        Write-Info '3. Toggle it OFF'
        Write-Info '4. Come back here and press Enter to continue'
        Write-Host ''

        $null = Read-Host 'Press Enter once you have toggled the alias off'

        if (Test-Path $aliasPath) {
            Stop-Phase 'PHASE C (Claude Desktop alias)' `
                "The Claude Desktop alias is still enabled." `
                @"
Please follow the four steps above one more time, then close this PowerShell
window and open a NEW PowerShell window before running the install command
again. Windows sometimes needs a fresh window for the change to take effect.
"@
        }
        Write-Ok 'Alias disabled. Continuing.'
    } else {
        Write-Ok 'No conflict found.'
    }
} catch {
    Stop-Phase 'PHASE C (Claude Desktop alias)' `
        "We could not finish the Claude Desktop check." `
        "Close this window, open a fresh PowerShell window, and try again."
}

# ---------------------------------------------------------------------------
# PHASE D. Install the official Claude Code native CLI
# ---------------------------------------------------------------------------

try {
    Write-Step 'PHASE D. Installing Claude Code'

    Write-Info "Running Anthropic's official installer."
    Write-Info 'This downloads the Claude Code CLI to your user folder.'
    Write-Host ''

    Invoke-RestMethod 'https://claude.ai/install.ps1' | Invoke-Expression

    $claudeBin = Join-Path $env:USERPROFILE '.local\bin\claude.exe'
    if (-not (Test-Path $claudeBin)) {
        Stop-Phase 'PHASE D (Claude Code install)' `
            "Claude Code did not install to the expected folder." `
            @"
The expected file was not found:
    $claudeBin

Please follow the official Claude Code setup guide:
    https://docs.claude.com/en/docs/claude-code/setup

Then run this installer again.
"@
    }
    Write-Ok "Claude Code installed at: $claudeBin"
} catch {
    Stop-Phase 'PHASE D (Claude Code install)' `
        "The Claude Code installer did not finish cleanly." `
        @"
Please follow the official Claude Code setup guide:
    https://docs.claude.com/en/docs/claude-code/setup

Then run this installer again.
"@
}

# ---------------------------------------------------------------------------
# PHASE E. Add the Claude Code folder to your user PATH
# ---------------------------------------------------------------------------

try {
    Write-Step 'PHASE E. Adding Claude Code to your PATH'

    $claudeDir = Join-Path $env:USERPROFILE '.local\bin'
    $userPath  = [Environment]::GetEnvironmentVariable('PATH', 'User')
    if ($null -eq $userPath) { $userPath = '' }

    $entries = $userPath.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)
    $alreadyOnPath = $false
    foreach ($entry in $entries) {
        if ($entry.TrimEnd('\') -ieq $claudeDir.TrimEnd('\')) {
            $alreadyOnPath = $true
            break
        }
    }

    if ($alreadyOnPath) {
        Write-Ok 'PATH already includes the Claude Code folder.'
    } else {
        $newPath = if ([string]::IsNullOrEmpty($userPath)) { $claudeDir } else { "$claudeDir;$userPath" }
        [Environment]::SetEnvironmentVariable('PATH', $newPath, 'User')
        Write-Ok 'Added Claude Code folder to the front of your user PATH.'
    }

    if (-not ($env:PATH -split ';' | ForEach-Object { $_.TrimEnd('\') } | Where-Object { $_ -ieq $claudeDir.TrimEnd('\') })) {
        $env:PATH = "$claudeDir;$env:PATH"
    }
    Write-Ok 'PATH refreshed for this window so the next step can find claude.'
} catch {
    Stop-Phase 'PHASE E (updating PATH)' `
        "We could not update your PATH automatically." `
        @"
Open Windows Settings, search for 'environment variables', and add this folder
to the top of your user PATH:

    $env:USERPROFILE\.local\bin

Then close this window, open a fresh PowerShell window, and run the install
command again.
"@
}

# ---------------------------------------------------------------------------
# PHASE F. Verify claude --version works
# ---------------------------------------------------------------------------

try {
    Write-Step 'PHASE F. Verifying Claude Code is working'

    $claudeBin = Join-Path $env:USERPROFILE '.local\bin\claude.exe'
    $versionOutput = & $claudeBin --version 2>&1

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace([string]$versionOutput)) {
        Stop-Phase 'PHASE F (verifying Claude Code)' `
            "Claude Code is installed but does not respond when we ask its version." `
            @"
Close this window, open a fresh PowerShell window, then type:

    claude --version

If that prints a version number, you are good. If it prints anything else, run:

    claude doctor

and share the output in AI Ad Lab Skool community.
"@
    }
    Write-Ok "Claude Code is working. Version: $versionOutput"
} catch {
    Stop-Phase 'PHASE F (verifying Claude Code)' `
        "We could not run Claude Code after install." `
        @"
Close this window, open a fresh PowerShell window, then type:

    claude --version

If that prints a version number, you are good. If it prints anything else, run:

    claude doctor

and share the output in AI Ad Lab Skool community.
"@
}

# ---------------------------------------------------------------------------
# PHASE G. Add the marketplace and install the plugin
# ---------------------------------------------------------------------------

try {
    Write-Step 'PHASE G. Installing AI Ad Lab plugin'

    $claudeBin = Join-Path $env:USERPROFILE '.local\bin\claude.exe'

    $existingMarketplaces = & $claudeBin plugin marketplace list 2>$null | Out-String
    if ($existingMarketplaces -match 'ai-ad-lab') {
        Write-Ok 'Marketplace already added. Skipping.'
    } else {
        Write-Info 'Adding AI Ad Lab marketplace.'
        & $claudeBin plugin marketplace add the-ai-ad-lab/ai-ad-lab
        if ($LASTEXITCODE -ne 0) {
            Stop-Phase 'PHASE G (adding marketplace)' `
                "Adding the marketplace did not complete." `
                @"
Open a new PowerShell window and run this command on its own to see the full
error message:

    claude plugin marketplace add the-ai-ad-lab/ai-ad-lab

Then share the output in AI Ad Lab Skool community.
"@
        }
        Write-Ok 'Marketplace added.'
    }

    $existingPlugins = & $claudeBin plugin list 2>$null | Out-String
    if ($existingPlugins -match 'ai-ad-lab') {
        Write-Ok 'Plugin already installed. Skipping.'
    } else {
        Write-Info 'Installing AI Ad Lab plugin.'
        & $claudeBin plugin install 'ai-ad-lab@ai-ad-lab'
        if ($LASTEXITCODE -ne 0) {
            Stop-Phase 'PHASE G (installing plugin)' `
                "Installing the plugin did not complete." `
                @"
Open a new PowerShell window and run this command on its own to see the full
error message:

    claude plugin install ai-ad-lab@ai-ad-lab

Then share the output in AI Ad Lab Skool community.
"@
        }
        Write-Ok 'Plugin installed.'
    }
} catch {
    Stop-Phase 'PHASE G (plugin install)' `
        "We could not finish installing the plugin." `
        @"
Open a new PowerShell window and run these two commands one at a time to see
the full error messages:

    claude plugin marketplace add the-ai-ad-lab/ai-ad-lab
    claude plugin install ai-ad-lab@ai-ad-lab

Then share the output in AI Ad Lab Skool community.
"@
}

# ---------------------------------------------------------------------------
# PHASE H. Final success message and PATH refresh instruction
# ---------------------------------------------------------------------------

try {
    Write-Step 'PHASE H. All done'

    Write-Host '    ============================================================' -ForegroundColor Green
    Write-Host '    AI Ad Lab is installed.' -ForegroundColor Green
    Write-Host '    ============================================================' -ForegroundColor Green
    Write-Host ''
    Write-Info 'One last step: close this PowerShell window and open a NEW PowerShell'
    Write-Info 'window. PATH changes only apply to new windows.'
    Write-Host ''
    Write-Info 'Then in the new window, type:'
    Write-Info ''
    Write-Info '    claude'
    Write-Host ''
    Write-Info 'Once Claude Code starts, run these three commands in order:'
    Write-Info ''
    Write-Info '    /ai-ad-lab:setup'
    Write-Info '    /ai-ad-lab:welcome'
    Write-Info '    /ai-ad-lab:doctor'
    Write-Host ''
    Write-Info 'If anything looks wrong, run /ai-ad-lab:doctor and share the'
    Write-Info 'output in Skool.'
    Write-Host ''
} catch {
    Stop-Phase 'PHASE H (final message)' `
        "The plugin installed but the script could not print the final message." `
        "Close this window, open a fresh PowerShell window, type 'claude' and run /ai-ad-lab:welcome."
}

exit 0
