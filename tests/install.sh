#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/btools-install.XXXXXX")"
trap 'rm -r -- "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/stubs" "$tmp/home"
cp "$root/install.sh" "$tmp/install.sh"
cat > "$tmp/bin/btools" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$BTOOLS_LOG"
EOF
chmod +x "$tmp/bin/btools"
for tool in powershell.exe wslpath; do
  printf '#!/usr/bin/env bash\n' > "$tmp/stubs/$tool"
  chmod +x "$tmp/stubs/$tool"
done

run_install() {
  : > "$tmp/log"
  HOME="$tmp/home" BTOOLS_LOG="$tmp/log" PATH="$tmp/stubs:$PATH" "$tmp/install.sh" "$@"
}

run_install --non-interactive --client both --browser both
diff -u <(printf 'setup\nsetup:chrome\n') "$tmp/log"
test "$(readlink "$tmp/home/.local/bin/btools")" = "$tmp/bin/btools"

run_install --non-interactive --client claude --browser chrome
diff -u <(printf 'setup:chrome --client claude\n') "$tmp/log"

run_install --client opencode --browser playwright
diff -u <(printf 'setup --client opencode\n') "$tmp/log"

if command -v script >/dev/null; then
  : > "$tmp/log"
  printf '2\n1\n' | HOME="$tmp/home" BTOOLS_LOG="$tmp/log" PATH="$tmp/stubs:$PATH" \
    script -q -c "$tmp/install.sh" /dev/null > /dev/null
  diff -u <(printf 'setup --client claude\n') "$tmp/log"
fi

if run_install --non-interactive --client both > /dev/null 2>&1; then
  echo 'Missing browser choice should fail.' >&2
  exit 1
fi
if run_install --client invalid --browser playwright > /dev/null 2>&1; then
  echo 'Invalid client should fail.' >&2
  exit 1
fi
echo 'PASS: installer selections and non-interactive validation'
