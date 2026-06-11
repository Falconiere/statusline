#!/usr/bin/env bash
# Install the statusline: point Claude Code's statusLine at this repo's
# statusline.sh by absolute path. Patches settings.json with jq, after backup.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
STATUSLINE="${SCRIPT_DIR}/statusline.sh"

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required but not found in PATH" >&2
  exit 1
fi

if [ ! -f "$STATUSLINE" ]; then
  echo "error: statusline.sh not found at ${STATUSLINE}" >&2
  exit 1
fi

config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
settings="${config_dir}/settings.json"
command_value="bash ${STATUSLINE}"

mkdir -p "$config_dir"
if [ ! -f "$settings" ]; then
  echo '{}' > "$settings"
  echo "created ${settings}"
fi

# Reject a settings file that is not valid JSON before touching it.
if ! jq empty "$settings" >/dev/null 2>&1; then
  echo "error: ${settings} is not valid JSON; refusing to patch" >&2
  exit 1
fi

stamp=$(date +%Y%m%d%H%M%S)
backup="${settings}.bak.${stamp}"
cp "$settings" "$backup"
echo "backed up ${settings} -> ${backup}"

tmp="${settings}.tmp.${stamp}"
jq --arg cmd "$command_value" \
  '.statusLine = {"type":"command","command":$cmd}' \
  "$settings" > "$tmp"
mv "$tmp" "$settings"

echo "set statusLine.command = ${command_value}"
echo "done. Restart Claude Code (or open a new session) to see it."
