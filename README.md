# browser-tools

`btools` sets up browser MCP servers for OpenCode and Claude Code:

- **Playwright:** isolated, headless Chromium (no existing tabs or logins).
- **Chrome:** your Windows Chrome tabs and logins, accessed from WSL. Requires
  approval through the Playwright extension.

Requires Node.js 22.18+ and npm. Chrome also requires WSL with x64 Windows.

## Install

```sh
git clone https://github.com/mirai-toto/browser-tools.git ~/Personal/GitHub/browser-tools
~/Personal/GitHub/browser-tools/install.sh
```

The installer asks which clients (OpenCode, Claude Code, or both) and browsers
(Playwright, Chrome, or both) to set up. It installs the `btools` command in
`~/.local/bin` and registers the selected MCP servers. On Linux without WSL,
only Playwright is available.

For unattended installs, specify both choices:

```sh
./install.sh --non-interactive --client both --browser both       # WSL
./install.sh --non-interactive --client both --browser playwright # Linux
```

[linux-setup](https://github.com/mirai-toto/linux-setup) runs this unattended for
both clients: Playwright on Linux, and Playwright plus Chrome on WSL.

## Check and repair

```sh
btools test                       # Test against a local page
btools test https://opencode.ai   # Optional external site
btools status                     # Show registered servers
btools setup                      # Repair Playwright
btools setup:chrome               # Repair Chrome (WSL only)
```

The local test checks navigation, reading, typing, clicking, and screenshots,
then closes its browser. The MCP server starts a separate browser on demand.
Setup commands reinstall dependencies and replace only their own MCP entries.
Add `--client opencode` or `--client claude` to a setup command to register with
just one client instead of every installed client.

## Windows Chrome (existing tabs and logins)

If you did not select Chrome during installation, run this from WSL:

```sh
btools setup:chrome
```

Chrome need not be open during setup. To connect later, install the official
[Playwright Extension](https://chromewebstore.google.com/detail/playwright-extension/mmlmfjhmonkocbjadbfplnigmagldckm)
in Windows Chrome and approve the connection and tabs to share. **Only share
tabs you need:** the agent can read private content and act as your logged-in
account, and page content may reach your model provider. Disconnect in the
extension when finished.

Do not set `PLAYWRIGHT_MCP_EXTENSION_TOKEN`; it bypasses approval. The launcher
unsets it to retain manual approval. Chrome setup installs a verified, pinned
portable Windows Node.js and locked MCP packages in
`%LOCALAPPDATA%\browser-tools`; it needs no admin access, Windows PATH change,
Chrome debugging flags, or separate HTTP server. Screenshots and snapshots go
to `%LOCALAPPDATA%\browser-tools\output`.

With multiple Chrome profiles, Playwright uses the last-used profile with the
extension. To choose another, add `--profile-dir-name "Profile 2"` to
`scripts/chrome.sh` (check `chrome://version` for its name).

## Troubleshooting

If Linux browser libraries are missing, run
`~/Personal/GitHub/browser-tools/node_modules/.bin/playwright install-deps chromium`
(may require sudo). The browser sandbox stays enabled.

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
Update `node-windows.version` explicitly when upgrading the Windows runtime.

## Disconnect

- OpenCode: use `/mcps` to inspect or disconnect either server. To unregister,
  remove `mcp.servers.playwright` or `mcp.servers.chrome` from
  `~/.config/opencode/opencode.json`.
- Claude Code: use `/mcp` to inspect or disconnect. To unregister, run
  `claude mcp remove --scope user playwright` (or `chrome`).
