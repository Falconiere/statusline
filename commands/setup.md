---
description: Wire the bundled statusline.sh into ~/.claude/settings.json
allowed-tools: Bash(bash:*)
---

Run the bundled installer to point Claude Code's `statusLine` at this plugin's
`statusline.sh`. The installer backs up the existing settings (timestamped) and
patches `.statusLine` atomically.

Execute this command with the Bash tool, then report its output verbatim to the
user:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/install.sh"
```

If it succeeds, tell the user to restart Claude Code (or start a new session)
for the statusline to appear. If `jq` is missing or the installer prints an
error, surface that error and stop.
