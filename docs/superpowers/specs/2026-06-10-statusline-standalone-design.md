# Statusline Standalone Repo — Design

**Date:** 2026-06-10
**Status:** Approved

## Goal

Make the Claude Code statusline self-contained in `/Volumes/Projects/statusline`,
referenced by an absolute path from `~/.claude/settings.json`. No symbolic links.

## Background

The statusline currently lives at
`/Volumes/Projects/terminal/claude-code/statusline.sh` and is wired in
`~/.claude/settings.json` as:

```json
"statusLine": {
  "type": "command",
  "command": "bash /Volumes/Projects/terminal/claude-code/statusline.sh"
}
```

The user wants it relocated to a dedicated repo with a clean install, and to
avoid symlinks.

## Constraint (researched)

Claude Code **plugins cannot own the main `statusLine`**. A plugin's
`settings.json` supports only `agent` and `subagentStatusLine` keys (per
official plugins-reference docs). `${CLAUDE_PLUGIN_ROOT}` is only set in plugin
hook/command context, not when the statusLine command runs. Therefore the main
statusLine must be configured in the user's `~/.claude/settings.json` with an
explicit path. Packaging as a plugin buys nothing here.

**Decision:** standalone repo + absolute-path reference.

## File Layout

```
/Volumes/Projects/statusline/
├── statusline.sh    # verbatim port of the existing script
├── install.sh       # jq-patches settings.json + backup
├── README.md        # what it shows, install, manual snippet
└── docs/superpowers/specs/2026-06-10-statusline-standalone-design.md
```

## Components

### statusline.sh

Byte-for-byte copy of
`/Volumes/Projects/terminal/claude-code/statusline.sh`. No behavior change.

- Reads JSON from stdin, prints a single-line status string.
- Segments: `model | org | effort | ctx tokens | folder | branch | caveman`.
- Dependencies: `jq`, `git`.
- Self-contained: org lookup (`.claude.json` search order) and caveman flag
  logic (`$CLAUDE_CONFIG_DIR/.caveman-active`, symlink-refused, 64-byte cap,
  whitelisted modes) are unchanged.

### install.sh

Patches the user's Claude settings so the statusLine points at this repo's
`statusline.sh` by absolute path.

Behavior:

1. Resolve own directory absolutely: `SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)`.
2. Require `jq`; if missing, print error and exit non-zero.
3. Target settings file: `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json`.
   If the file does not exist, create it containing `{}` first.
4. Backup target → `settings.json.bak.<stamp>` where `<stamp>` comes from
   `date +%Y%m%d%H%M%S` at runtime.
5. Set `.statusLine = {"type":"command","command":"bash <SCRIPT_DIR>/statusline.sh"}`
   via `jq`, writing to a temp file then `mv` over the target (atomic).
6. Print confirmation including the command value written.

### README.md

- One-paragraph description of what the statusline displays.
- Install: `./install.sh`.
- Manual snippet for users who prefer to paste it themselves.
- Dependencies: `jq`, `git`.

## Edge Cases

- Missing `~/.claude/settings.json` → create `{}` before patching.
- `$CLAUDE_CONFIG_DIR` set → patch that file instead of `~/.claude`.
- `jq` absent → hard error, no partial write.
- Atomic write (tmp + `mv`) so a failed `jq` never corrupts settings.

## Verification

- Pipe a real Claude Code statusline JSON payload into `statusline.sh`; confirm
  output matches the current script's output (no mocks — use a real payload
  shape with the documented fields).
- Run `install.sh`; confirm `jq .statusLine settings.json` shows
  `bash /Volumes/Projects/statusline/statusline.sh` and that a `.bak.<stamp>`
  backup was created.
- Diff `statusline.sh` against the source to prove a verbatim port.

## Out of Scope

- No plugin packaging, no marketplace distribution.
- No visual/design changes to the statusline output (verbatim port).
- No symlinks.
