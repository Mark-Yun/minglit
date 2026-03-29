#!/bin/bash
# tpm-staff-run.sh — 단발성. audit-report 분석 → actionable 이슈 생성.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="/Users/mark/workspace/minglit"
PROMPT_FILE="$SCRIPT_DIR/prompts/tpm-staff.txt"
DIRECTION_FILE="$SCRIPT_DIR/prompts/direction.txt"
COMMON_FILE="$SCRIPT_DIR/prompts/worker-common.txt"
SESSION_TIMEOUT=3600
REPO="Mark-Yun/minglit"
LOG_DIR="/tmp/claude-tpm-logs"

mkdir -p "$LOG_DIR"
[ ! -f "$PROMPT_FILE" ] && echo "Error: Prompt not found" && exit 1

cd "$REPO_DIR" || exit 1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] TPM staff session starting..."

FULL_PROMPT="$(cat "$DIRECTION_FILE" 2>/dev/null)

$(cat "$COMMON_FILE" 2>/dev/null)

$(cat "$PROMPT_FILE")"

/usr/local/bin/claude -p "$FULL_PROMPT" \
    --max-turns 999 \
    --allowedTools "Bash,Read,Write,Edit,Glob,Grep,Agent" \
    2>&1 | tee "$LOG_DIR/tpm-$(date +%Y%m%d-%H%M%S).log" &
claude_pid=$!
( sleep "$SESSION_TIMEOUT" && kill "$claude_pid" 2>/dev/null ) &
timer_pid=$!
wait "$claude_pid" 2>/dev/null
kill "$timer_pid" 2>/dev/null; wait "$timer_pid" 2>/dev/null

echo "[$(date '+%Y-%m-%d %H:%M:%S')] TPM staff session done."
