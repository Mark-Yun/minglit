#!/bin/bash
# pm-staff-run.sh — 단발성. 이슈/감사 분석 → 기술 추천/기능 제안 리포트.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="/Users/mark/workspace/minglit"
PROMPT_FILE="$SCRIPT_DIR/prompts/pm-staff.txt"
SESSION_TIMEOUT=1800
REPO="Mark-Yun/minglit"
LOG_DIR="/tmp/claude-pm-staff-logs"

mkdir -p "$LOG_DIR"
[ ! -f "$PROMPT_FILE" ] && echo "Error: Prompt not found" && exit 1

cd "$REPO_DIR" || exit 1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] PM staff session starting..."

/usr/local/bin/claude -p "$(cat "$PROMPT_FILE")" \
    --max-turns 999 \
    --allowedTools "Bash,Read,Write,Edit,Glob,Grep,Agent,WebSearch,WebFetch" \
    2>&1 | tee "$LOG_DIR/pm-staff-$(date +%Y%m%d-%H%M%S).log" &
claude_pid=$!
( sleep "$SESSION_TIMEOUT" && kill "$claude_pid" 2>/dev/null ) &
timer_pid=$!
wait "$claude_pid" 2>/dev/null
kill "$timer_pid" 2>/dev/null; wait "$timer_pid" 2>/dev/null

echo "[$(date '+%Y-%m-%d %H:%M:%S')] PM staff session done."
