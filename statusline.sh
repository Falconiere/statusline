#!/usr/bin/env bash
# Claude Code statusline script
# Receives JSON via stdin and prints a single-line status string.

input=$(cat)

# --- Colors (ANSI) ---
CYAN=$'\033[36m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
MAGENTA=$'\033[35m'
BLUE=$'\033[34m'
RED=$'\033[31m'
DIM=$'\033[2m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

# --- Model ---
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')

# --- Thinking effort ---
effort=$(echo "$input" | jq -r '.effort.level // "none"')

# --- Context window ---
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
ctx_used=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Format a raw token number as e.g. "45k" or "200k"
format_tokens() {
  local n="$1"
  if [ "$n" -ge 1000 ] 2>/dev/null; then
    printf "%dk" "$(( n / 1000 ))"
  else
    printf "%d" "$n"
  fi
}

ctx_size_fmt=$(format_tokens "$ctx_size")
ctx_used_fmt=$(format_tokens "$ctx_used")

if [ -n "$ctx_pct" ]; then
  ctx_pct_fmt=$(printf "%.0f%%" "$ctx_pct")
  tokens_seg="${ctx_used_fmt} / ${ctx_size_fmt} (${ctx_pct_fmt})"
else
  tokens_seg="${ctx_used_fmt} / ${ctx_size_fmt}"
fi

# --- Organization (from oauthAccount.organizationName in .claude.json) ---
# Search order: $CLAUDE_CONFIG_DIR (set per-session by Claude Code), script dir, $HOME.
script_dir=$(cd "$(dirname "$0")" && pwd)
org_name=""
for candidate in \
  "${CLAUDE_CONFIG_DIR:+${CLAUDE_CONFIG_DIR}/.claude.json}" \
  "${script_dir}/.claude.json" \
  "${HOME}/.claude.json"; do
  [ -z "$candidate" ] && continue
  if [ -r "$candidate" ]; then
    org_name=$(jq -r '.oauthAccount.organizationName // empty' "$candidate" 2>/dev/null)
    if [ -n "$org_name" ]; then
      break
    fi
  fi
done

# Collapse a default org name like "user@example.com's Organization" to just "example.com".
if [[ "$org_name" =~ ^[^@]+@([^\']+)\'s\ Organization$ ]]; then
  org_name="${BASH_REMATCH[1]}"
fi

org_seg=""
if [ -n "$org_name" ]; then
  org_seg="org:${org_name}"
fi

# --- Git branch + folder ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
branch=""
folder=""
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  folder=$(basename "$cwd")
fi

# --- Caveman mode ---
# Read flag file at $CLAUDE_CONFIG_DIR/.caveman-active (written by
# caveman-activate.js). Hardening matches caveman-statusline.sh: refuse
# symlinks, cap read at 64 bytes, strip to [a-z0-9-], whitelist modes.
caveman_seg=""
caveman_flag="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/.caveman-active"
if [ -f "$caveman_flag" ] && [ ! -L "$caveman_flag" ]; then
  caveman_mode=$(head -c 64 "$caveman_flag" 2>/dev/null | tr -d '\n\r' | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-')
  case "$caveman_mode" in
    off) ;;
    "")
      caveman_seg="${BOLD}${GREEN}[CAVEMAN]${RESET}" ;;
    full|lite|ultra|wenyan-lite|wenyan|wenyan-full|wenyan-ultra|commit|review|compress)
      caveman_upper=$(printf '%s' "$caveman_mode" | tr '[:lower:]' '[:upper:]')
      caveman_seg="${BOLD}${GREEN}[CAVEMAN:${caveman_upper}]${RESET}" ;;
  esac
fi

# --- Assemble ---
sep="${DIM} | ${RESET}"

line="${CYAN}${model}${RESET}"

if [ -n "$org_seg" ]; then
  line="${line}${sep}${GREEN}${org_seg}${RESET}"
fi

line="${line}${sep}${YELLOW}effort:${effort}${RESET}${sep}${MAGENTA}ctx:${tokens_seg}${RESET}"

if [ -n "$folder" ]; then
  line="${line}${sep}${BOLD}${folder}${RESET}"
fi

if [ -n "$branch" ]; then
  line="${line}${sep}${BLUE}${branch}${RESET}"
fi

if [ -n "$caveman_seg" ]; then
  line="${line}${sep}${caveman_seg}"
fi

printf "%s" "$line"
