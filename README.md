# statusline

Self-contained Claude Code statusline. A single bash script that reads the
statusline JSON payload on stdin and prints a one-line status string.

## What it shows

`model | org | effort:<level> | ctx:<used>/<size> (<pct>) | folder | branch | [CAVEMAN:<mode>]`

- **model** — display name of the active model
- **org** — organization name (collapsed from the default `…'s Organization` form)
- **effort** — thinking effort level
- **ctx** — context-window tokens used / total, with percentage
- **folder** — basename of the current workspace directory
- **branch** — current git branch
- **[CAVEMAN]** — present only when the caveman flag file is active

## Install

```bash
./install.sh
```

This backs up `~/.claude/settings.json` (timestamped) and sets:

```json
"statusLine": {
  "type": "command",
  "command": "bash /absolute/path/to/statusline.sh"
}
```

Respects `$CLAUDE_CONFIG_DIR` if set. Restart Claude Code (or start a new
session) to pick it up.

## Manual setup

Prefer to wire it yourself? Add this to `~/.claude/settings.json`, using the
absolute path to `statusline.sh` in this repo:

```json
"statusLine": {
  "type": "command",
  "command": "bash /Volumes/Projects/statusline/statusline.sh"
}
```

## Dependencies

- `jq`
- `git`

## Notes

Claude Code plugins cannot provide the main `statusLine` (only `agent` and
`subagentStatusLine` plugin settings are supported), so this is shipped as a
standalone script referenced by absolute path — no symlinks, no plugin wiring.
