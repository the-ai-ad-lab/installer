# AI Ad Lab Installer

Public bootstrap installer for AI Ad Lab plugin. Members of AI Ad Lab Skool community use this to set up the plugin on a fresh machine.

## One liner install

### macOS

```
curl -fsSL https://raw.githubusercontent.com/the-ai-ad-lab/installer/main/install.sh | bash
```

### Windows (PowerShell)

```
irm https://raw.githubusercontent.com/the-ai-ad-lab/installer/main/install.ps1 | iex
```

You will see at most two prompts during install. The script will tell you exactly what to click.

#### Windows troubleshooting

* **claude command not found after install.** Close PowerShell and open a new window. PATH changes only apply to new windows.
* **Script says alias is still enabled after I toggled it.** Open a new PowerShell window and run the command again.
* **Anything else.** Run `/ai-ad-lab:doctor` inside Claude Code and share the output in Skool.

## What gets installed

The bootstrap installer puts these on your machine if they aren't already there:

1. **Claude Code** via Anthropic's official installer at `https://claude.ai/install.ps1` (Windows) or `https://claude.ai/install.sh` (macOS). The CLI lands in `~/.local/bin/`.
2. **GitHub CLI** (`gh`) via Homebrew on macOS. Not installed by the Windows script.
3. **GitHub authentication** via interactive device code in your browser (macOS only).
4. **AI Ad Lab marketplace** added to your Claude Code config (`claude plugin marketplace add the-ai-ad-lab/ai-ad-lab`)
5. **AI Ad Lab plugin** installed from that marketplace (`claude plugin install ai-ad-lab@ai-ad-lab`)

If Claude Code is already on your PATH, the installer first runs a pre-flight smoke test (`claude --version`) to make sure the existing install actually works. If it does not, the installer exits early with a pointer to the official Claude Code setup guide before touching anything else.

## What to run after the bootstrap

When the bootstrap finishes, open Claude Code and run, in order:

1. `/ai-ad-lab:setup` finishes the rest of the configuration. It detects your OS, installs any missing dev tools (git, Node 20+, Python 3.12+, ffmpeg), pre-warms Playwright Chromium, and verifies the four MCP servers are wired up.
2. `/ai-ad-lab:welcome` greets you, lists every integrated skill grouped by stage, and points you to `/ai-ad-lab:next` as the always-on guide for the next best step in your current project.
3. `/ai-ad-lab:doctor` is the diagnostic checklist you can run any time to verify the marketplace, the plugin, all four MCP servers, your Fal AI key, your Meta Ads credentials, and the bundled Claude CLI on your PATH.

All AI Ad Lab slash commands are namespaced with the `ai-ad-lab:` prefix. On Claude Code 2.1.x the prefix is required for plugin commands, so always use the full `/ai-ad-lab:<command>` form.

## Requirements

1. **Active membership in AI Ad Lab Skool community.** Your Skool subscription gives you access to the private GitHub repo `the-ai-ad-lab/ai-ad-lab`. New members are added to the team within 24 hours of subscribing. If you don't yet have access, the installer detects that and exits with a clear message.

2. **macOS or Windows.** Linux is not supported.

## What this repo does NOT contain

The actual plugin (skills, MCP servers, workflows, hooks) lives in a separate private repo accessible only to active Skool community members. This public repo holds only the two bootstrap scripts and this README.

## Support

Questions, bugs, or installer issues: post in AI Ad Lab Skool community.

## License

MIT. See [LICENSE](LICENSE).
