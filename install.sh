#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage: ./install.sh [--client opencode|claude|both] [--browser playwright|chrome|both] [--non-interactive]

With a terminal, missing choices are prompted. For unattended installs, provide
both choices and --non-interactive. Chrome requires WSL with x64 Windows; Chrome
and the Playwright extension do not need to be open during setup.
EOF
}

choose() {
  local label="$1" first="$2" second="$3" answer
  while true; do
    printf '%s (1=%s, 2=%s, 3=both) [3]: ' "$label" "$first" "$second" >&2
    read -r answer || return 1
    case "$answer" in
      1) printf '%s' "$first"; return ;;
      2) printf '%s' "$second"; return ;;
      3 | '') printf 'both'; return ;;
      *) printf 'Choose 1, 2, or 3.\n' >&2 ;;
    esac
  done
}

client=""
browser=""
non_interactive=false
while (( $# > 0 )); do
  case "$1" in
    --client) client="${2:?--client needs a value}"; shift 2 ;;
    --client=*) client="${1#--client=}"; shift ;;
    --browser) browser="${2:?--browser needs a value}"; shift 2 ;;
    --browser=*) browser="${1#--browser=}"; shift ;;
    --non-interactive) non_interactive=true; shift ;;
    -h | --help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$client" || -z "$browser" ]]; then
  if [[ "$non_interactive" == true || ! -t 0 || ! -t 1 ]]; then
    printf 'Specify both --client and --browser for a non-interactive install.\n' >&2
    exit 2
  fi
  if [[ -z "$client" ]]; then
    client="$(choose 'Clients' opencode claude)"
  fi
  if [[ -z "$browser" ]]; then
    if command -v powershell.exe >/dev/null && command -v wslpath >/dev/null; then
      browser="$(choose 'Browsers' playwright chrome)"
    else
      browser=playwright
      printf 'Windows Chrome unavailable; selecting Playwright.\n' >&2
    fi
  fi
fi

case "$client" in
  opencode | claude | both) ;;
  *) printf 'Invalid client: %s\n' "$client" >&2; exit 2 ;;
esac
case "$browser" in
  playwright | chrome | both) ;;
  *) printf 'Invalid browser: %s\n' "$browser" >&2; exit 2 ;;
esac

if [[ "$browser" != playwright ]] && { ! command -v powershell.exe >/dev/null || ! command -v wslpath >/dev/null; }; then
  printf 'Chrome setup requires WSL with Windows interop; choose --browser playwright on Linux.\n' >&2
  exit 1
fi

mkdir -p "$HOME/.local/bin"
ln -sfn "$root/bin/btools" "$HOME/.local/bin/btools"

client_args=()
if [[ "$client" != both ]]; then
  client_args=(--client "$client")
fi
if [[ "$browser" != chrome ]]; then
  "$root/bin/btools" setup "${client_args[@]}"
fi
if [[ "$browser" != playwright ]]; then
  "$root/bin/btools" setup:chrome "${client_args[@]}"
fi
