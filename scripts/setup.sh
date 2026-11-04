#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$root/scripts/register.sh"
select_clients "$@"
cd "$root"
npm ci
./node_modules/.bin/playwright install chromium --no-shell
npm test
register_mcp playwright "$(command -v node)" -- "$root/src/mcp.ts"
list_mcp
