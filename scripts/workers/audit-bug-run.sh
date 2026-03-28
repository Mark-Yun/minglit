#!/bin/bash
# audit-bug-run.sh — 단발성. launchd가 주기적 호출.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="/Users/mark/workspace/minglit"
WORKTREE_DIR="/Users/mark/workspace/minglit-workers/audit-bug"
PROMPT_FILE="$SCRIPT_DIR/prompts/audit-bug.txt"
COMMON_FILE="$SCRIPT_DIR/prompts/worker-common.txt"
SESSION_TIMEOUT=3600
REPO="Mark-Yun/minglit"

[ ! -f "$PROMPT_FILE" ] && echo "Error: Prompt not found" && exit 1

if [ ! -d "$WORKTREE_DIR" ]; then
    mkdir -p "$(dirname "$WORKTREE_DIR")"
    git -C "$REPO_DIR" worktree add --detach "$WORKTREE_DIR" origin/dev 2>&1
fi

cd "$WORKTREE_DIR" || exit 1
git fetch origin dev && git reset --hard origin/dev 2>/dev/null

LOG_DIR="/tmp/claude-worker-logs"
mkdir -p "$LOG_DIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running audit-bug..."

/usr/local/bin/claude -p "$(cat "$COMMON_FILE" 2>/dev/null)

$(cat "$PROMPT_FILE")" \
    --max-turns 999 \
    --allowedTools "Bash,Read,Write,Edit,Glob,Grep,Agent" \
    2>&1 | tee "$LOG_DIR/audit-bug-$(date +%Y%m%d-%H%M%S).log" &
claude_pid=$!
( sleep "$SESSION_TIMEOUT" && kill "$claude_pid" 2>/dev/null ) &
timer_pid=$!
wait "$claude_pid" 2>/dev/null
kill "$timer_pid" 2>/dev/null; wait "$timer_pid" 2>/dev/null

echo "[$(date '+%Y-%m-%d %H:%M:%S')] audit-bug done."
