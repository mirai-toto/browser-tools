#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$HOME/.local/bin"
ln -sfn "$root/bin/btools" "$HOME/.local/bin/btools"
exec "$root/bin/btools" setup "$@"
