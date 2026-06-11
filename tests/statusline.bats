#!/usr/bin/env bats
# Real-data tests: feed statusline.sh a real Claude Code payload shape and
# exercise install.sh against an isolated config dir. No mocks.

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  STATUSLINE="$REPO_ROOT/statusline.sh"
  INSTALL="$REPO_ROOT/install.sh"
}

# ANSI color codes wrap whole segments, so the inner text stays contiguous and
# substring assertions work directly on the raw output.

@test "statusline.sh renders model, effort and context from a real payload" {
  payload='{"model":{"display_name":"Opus 4.8"},"effort":{"level":"high"},"context_window":{"context_window_size":200000,"total_input_tokens":45000,"used_percentage":22.5},"workspace":{"current_dir":"'"$REPO_ROOT"'"}}'
  run bash -c "printf '%s' '$payload' | bash '$STATUSLINE'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Opus 4.8"* ]]
  [[ "$output" == *"effort:high"* ]]
  [[ "$output" == *"ctx:45k / 200k (22%)"* ]]
}

@test "statusline.sh falls back to Unknown model on empty payload" {
  run bash -c "printf '%s' '{}' | bash '$STATUSLINE'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Unknown"* ]]
}

@test "install.sh patches statusLine and creates a backup in an isolated config dir" {
  tmp="$(mktemp -d)"
  run env CLAUDE_CONFIG_DIR="$tmp" bash "$INSTALL"
  [ "$status" -eq 0 ]
  cmd="$(jq -r '.statusLine.command' "$tmp/settings.json")"
  [ "$cmd" = "bash $STATUSLINE" ]
  [ "$(jq -r '.statusLine.type' "$tmp/settings.json")" = "command" ]
  # A timestamped backup must exist.
  ls "$tmp"/settings.json.bak.* >/dev/null
  rm -rf "$tmp"
}

@test "install.sh preserves existing settings keys" {
  tmp="$(mktemp -d)"
  printf '%s' '{"theme":"dark","permissions":{"defaultMode":"auto"}}' > "$tmp/settings.json"
  run env CLAUDE_CONFIG_DIR="$tmp" bash "$INSTALL"
  [ "$status" -eq 0 ]
  [ "$(jq -r '.theme' "$tmp/settings.json")" = "dark" ]
  [ "$(jq -r '.permissions.defaultMode' "$tmp/settings.json")" = "auto" ]
  [ "$(jq -r '.statusLine.command' "$tmp/settings.json")" = "bash $STATUSLINE" ]
  rm -rf "$tmp"
}
