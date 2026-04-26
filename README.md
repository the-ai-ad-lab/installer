# The AI Ad Lab Installer

Public bootstrap installer for The AI Ad Lab plugin. Members of The AI Ad Lab Skool community use this to set up the plugin on a fresh machine.

## One liner install

### macOS

```
curl -fsSL https://raw.githubusercontent.com/the-ai-ad-lab/installer/main/install.sh | bash
```

### Windows (PowerShell)

```
irm https://raw.githubusercontent.com/the-ai-ad-lab/installer/main/install.ps1 | iex
```

That's it. The installer walks through seven steps, prints clear status before each, and exits cleanly with one line fix instructions if anything fails.

## What gets installed

The bootstrap installer puts these on your machine if they aren't already there:

1. **Claude Code** via Anthropic's official installer (macOS) or winget (Windows)
2. **GitHub CLI** (`gh`) via Homebrew (macOS) or winget (Windows)
3. **GitHub authentication** via interactive device code in your browser
4. **The AI Ad Lab plugin** added to your Claude Code marketplace and installed at user scope

After the bootstrap completes, open Claude Code and run `/ai-ad-lab:setup` inside Claude Code. That command finishes the rest of the setup: missing dev tools (git, Node 20+, Python 3.12+, ffmpeg), Playwright Chromium, project folder structure, and the four MCP servers.

## Requirements

1. **Active membership in The AI Ad Lab Skool community.** Your Skool subscription gives you access to the private GitHub repo `the-ai-ad-lab/ai-ad-lab`. New members are added to the team within 24 hours of subscribing. If you don't yet have access, the installer detects that and exits with a clear message.

2. **macOS or Windows.** Linux is not supported.

## What this repo does NOT contain

The actual plugin (skills, MCP servers, workflows, hooks) lives in a separate private repo accessible only to active Skool community members. This public repo holds only the two bootstrap scripts and this README.

## Support

Questions, bugs, or installer issues: post in The AI Ad Lab Skool community.

## License

MIT. See [LICENSE](LICENSE).
