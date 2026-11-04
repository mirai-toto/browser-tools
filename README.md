# browser-tools

`btools` sets up and tests browser MCP servers for OpenCode and Claude Code:

- `playwright`: separate headless, isolated Chromium.
- `chrome`: existing Windows Chrome tabs and logins, from WSL.

Requires Node.js 22.18+ and npm. Dependencies are pinned in `package.json` and
`package-lock.json`.

`install.sh` is the entry point; `bin/btools` is the CLI, `scripts/` contains
setup and launch helpers, `src/` contains the Playwright launcher, and `tests/`
contains the smoke test.

## Install

```sh
git clone https://github.com/mirai-toto/browser-tools.git ~/Personal/GitHub/browser-tools
~/Personal/GitHub/browser-tools/install.sh
```

[linux-setup](https://github.com/mirai-toto/linux-setup) clones the repo next to
its own checkout and runs `install.sh` unattended for both clients: Playwright
on Linux, plus Windows Chrome on WSL. On a terminal, the installer prompts for
OpenCode, Claude Code, or both, and Playwright, Chrome, or both. It links
`~/.local/bin/btools` and sets up the selected browser servers.

For an unattended install, provide both choices explicitly:

```sh
./install.sh --non-interactive --client both --browser both  # WSL
./install.sh --non-interactive --client both --browser playwright  # Linux
```

Use `btools setup` or `btools setup:chrome` to repair an individual server.

`setup` installs locked dependencies, downloads matching Chromium, runs the local
smoke test, and registers `playwright` globally with every installed client:
OpenCode (`opencode mcp add --global`) and Claude Code (`claude mcp add --scope
user`). Pass `--client opencode` or `--client claude` to `btools setup` to register with only one.
Re-running repairs the installation and replaces only the same named MCP entry.

`playwright` uses separate headless, isolated Chromium, not existing tabs or
logins. The launcher resolves Chromium's path from Playwright, rather than
hardcoding a revision. Downloads live in `~/.cache/ms-playwright`; screenshots
and snapshots live in `output/`.

If Linux browser libraries are missing, run
`~/Personal/GitHub/browser-tools/node_modules/.bin/playwright install-deps chromium`
(may require sudo). The browser sandbox stays enabled.

## Test

```sh
btools test
# Optional external website check:
btools test https://opencode.ai
btools status
```

The default test serves a local page and checks navigation, reading, typing,
clicking, and screenshots without an external website. It closes the test browser
afterward; MCP starts its own browser on demand. `status` lists the MCP servers
registered with each installed client.

## Windows Chrome (existing tabs and logins)

From WSL, run this if Chrome was not selected during installation:

```sh
btools setup:chrome
```

Setup does not need Chrome to be open. To connect later, install the official
[Playwright Extension](https://chromewebstore.google.com/detail/playwright-extension/mmlmfjhmonkocbjadbfplnigmagldckm)
in Windows Chrome and approve access to the tabs you want to share.

Setup requires x64 Windows. It installs a pinned portable Windows Node.js from
nodejs.org, verifies its published SHA-256 checksum, and installs locked MCP
packages in `%LOCALAPPDATA%\browser-tools`. No admin installation, Windows PATH
changes, Chrome remote-debugging flags, or extension token are needed. MCP uses
standard input/output through WSL; no separate HTTP server is exposed.

The second global MCP entry is `chrome`; `playwright` remains unchanged. Approve
the connection in Chrome and share only the tabs needed for the task. The agent
can read private content and act as your logged-in account; page content may
reach your model provider. Disconnect through the extension when finished.

Do not configure `PLAYWRIGHT_MCP_EXTENSION_TOKEN`: it bypasses approval. The
launcher unsets it to retain manual approval. Screenshots and snapshots go to
`%LOCALAPPDATA%\browser-tools\output`. If several profiles have the extension,
Playwright uses the last-used one; add `--profile-dir-name "Profile 2"` to
`scripts/chrome.sh` to select a profile (see `chrome://version`).

Re-run `setup:chrome` to repair or after dependency updates. Update
`node-windows.version` explicitly when upgrading the Windows runtime.

## Update dependencies

```sh
cd ~/Personal/GitHub/browser-tools
npm install --save-exact @playwright/mcp@latest
npm install --save-exact "playwright@$(node -p "require('./node_modules/@playwright/mcp/package.json').dependencies.playwright")"
btools setup
# If using Windows Chrome:
btools setup:chrome
```

Commit both manifests for reproducible reinstalls.

## Disconnect

- OpenCode: use `/mcps` to inspect or disconnect either server. To unregister,
  remove `mcp.servers.playwright` or `mcp.servers.chrome` from
  `~/.config/opencode/opencode.json`.
- Claude Code: use `/mcp` to inspect or disconnect. To unregister, run
  `claude mcp remove --scope user playwright` (or `chrome`).
