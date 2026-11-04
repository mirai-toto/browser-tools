#!/usr/bin/env bash
# Shared by setup and status: selects MCP clients and registers servers with them.
supported_clients=(opencode claude)
clients=()

# Accepts --client NAME; defaults to every installed supported client.
select_clients() {
  local requested=""
  while (( $# > 0 )); do
    case "$1" in
      --client) requested="${2:?--client needs a value}"; shift 2 ;;
      --client=*) requested="${1#--client=}"; shift ;;
      *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
  done

  local client
  for client in "${supported_clients[@]}"; do
    if [[ -n "$requested" && "$client" != "$requested" ]]; then
      continue
    fi
    if command -v "$client" >/dev/null; then
      clients+=("$client")
    fi
  done

  if [[ -n "$requested" ]] && (( ${#clients[@]} == 0 )); then
    echo "Client not supported or not installed: $requested" >&2
    exit 1
  fi
  if (( ${#clients[@]} == 0 )); then
    echo "No supported MCP client installed (${supported_clients[*]})." >&2
    exit 1
  fi
}

# Usage: register_mcp NAME COMMAND [ARGS...]. Re-running replaces the same entry.
register_mcp() {
  local name="$1"
  shift
  local client
  for client in "${clients[@]}"; do
    case "$client" in
      opencode) opencode mcp add "$name" --global -- "$@" ;;
      claude)
        claude mcp remove --scope user "$name" >/dev/null 2>&1 || true
        claude mcp add --scope user "$name" -- "$@"
        ;;
    esac
  done
}

list_mcp() {
  local client
  for client in "${clients[@]}"; do
    printf '== %s\n' "$client"
    (cd "$HOME" && "$client" mcp list)
  done
}
