---
description: Wire the bundled statusline.sh into ~/.claude/settings.json
allowed-tools: Bash(jq:*), Bash(cp:*), Bash(mkdir:*), Bash(date:*), Bash(mv:*), Bash(echo:*)
---

Set the Claude Code `statusLine` to the bundled script. This backs up the
existing settings (timestamped) and patches `.statusLine` atomically.

!`config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"; settings="$config_dir/settings.json"; mkdir -p "$config_dir"; [ -f "$settings" ] || echo '{}' > "$settings"; if ! jq empty "$settings" >/dev/null 2>&1; then echo "ERROR: $settings is not valid JSON; aborting"; else stamp=$(date +%Y%m%d%H%M%S); cp "$settings" "$settings.bak.$stamp"; jq '.statusLine = {"type":"command","command":"bash ${CLAUDE_PLUGIN_ROOT}/statusline.sh"}' "$settings" > "$settings.tmp.$stamp" && mv "$settings.tmp.$stamp" "$settings" && echo "OK: statusLine set to bash ${CLAUDE_PLUGIN_ROOT}/statusline.sh (backup: $settings.bak.$stamp)"; fi`

Report the result of the command above to the user. If it succeeded, tell them
to restart Claude Code (or start a new session) for the statusline to appear.
