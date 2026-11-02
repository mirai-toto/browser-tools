#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$root/register.sh"
select_clients "$@"
cd "$root"
npm ci
./node_modules/.bin/playwright install chromium --no-shell
npm test
register_mcp playwright "$(command -v node)" -- "$root/mcp.ts"
list_mcp
