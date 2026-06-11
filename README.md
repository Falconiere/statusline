# statusline

Self-contained Claude Code statusline. A single bash script that reads the
statusline JSON payload on stdin and prints a one-line status string. Ships as
a Claude Code plugin with a `/statusline:setup` command that wires it into your
settings — no symlinks, no hand-editing absolute paths.

## What it shows

`model | org | effort:<level> | ctx:<used>/<size> (<pct>) | folder | branch | [CAVEMAN:<mode>]`

- **model** — display name of the active model
- **org** — organization name (collapsed from the default `…'s Organization` form)
- **effort** — thinking effort level
- **ctx** — context-window tokens used / total, with percentage
- **folder** — basename of the current workspace directory
- **branch** — current git branch
- **[CAVEMAN]** — present only when the caveman flag file is active

## Install (plugin — recommended)

```text
/plugin marketplace add JuliusBrussee/caveman
/plugin marketplace add Falconiere/statusline
/plugin install statusline@falconiere-statusline
/statusline:setup
```

- The first `marketplace add` registers the **caveman** marketplace. `statusline`
  declares `caveman` as a dependency, so its marketplace must be known before
  install (cross-marketplace dependencies are not auto-discovered).
- The second `marketplace add` registers this repo as a plugin marketplace.
- `install` adds the `statusline` plugin (bundles `statusline.sh`) and pulls in
  `caveman@caveman` automatically.
- `/statusline:setup` backs up `~/.claude/settings.json` (timestamped) and sets
  `.statusLine.command` to `bash ${CLAUDE_PLUGIN_ROOT}/statusline.sh`, where
  `${CLAUDE_PLUGIN_ROOT}` resolves to the installed plugin directory.

> Note: `/plugin add ...` is not a real command. Use
> `/plugin marketplace add ...` then `/plugin install ...` as shown above.

Restart Claude Code (or start a new session) after setup to see it.

### Dependency: caveman

`statusline` depends on the [caveman](https://github.com/JuliusBrussee/caveman)
plugin (`dependencies` in `plugin.json`, allow-listed via
`allowCrossMarketplaceDependenciesOn` in `marketplace.json`). Installing
`statusline` auto-installs `caveman@caveman`; if caveman is missing or disabled,
statusline reports `dependency-unsatisfied`. The `[CAVEMAN:<mode>]` segment then
reflects caveman's active mode via its `$CLAUDE_CONFIG_DIR/.caveman-active` flag.

### Why a setup command instead of automatic wiring

Claude Code plugins cannot contribute the main `statusLine` directly — a
plugin's `settings.json` supports only `agent` and `subagentStatusLine`. So the
plugin bundles the script and the `/statusline:setup` command patches your user
settings to point at it.

## Install (manual — no plugin)

Clone the repo, then:

```bash
./install.sh
```

`install.sh` backs up `~/.claude/settings.json` (timestamped) and sets:

```json
"statusLine": {
  "type": "command",
  "command": "bash /absolute/path/to/statusline.sh"
}
```

Respects `$CLAUDE_CONFIG_DIR` if set.

Prefer to wire it yourself? Add this to `~/.claude/settings.json`, using the
absolute path to `statusline.sh`:

```json
"statusLine": {
  "type": "command",
  "command": "bash /path/to/statusline/statusline.sh"
}
```

## Dependencies

- `jq`
- `git`

## Repo layout

```text
.claude-plugin/
  plugin.json        plugin manifest
  marketplace.json   marketplace catalog (this repo is its own marketplace)
commands/
  setup.md           /statusline:setup — patches settings.json
statusline.sh        the statusline script (reads JSON stdin, prints one line)
install.sh           manual installer (non-plugin)
```
