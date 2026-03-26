#!/bin/bash
# audit-qa-worker.sh — git worktree 격리 + 24시간 단위 감사

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="/Users/mark/workspace/minglit"
WORKTREE_DIR="/Users/mark/workspace/minglit-workers/audit-qa"
PROMPT_FILE="$SCRIPT_DIR/prompts/audit-qa.txt"
POLL_INTERVAL=86400  # 24시간

if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: Prompt file not found: $PROMPT_FILE"
    exit 1
fi

# Worktree 초기화 (최초 1회)
if [ ! -d "$WORKTREE_DIR" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Creating worktree at $WORKTREE_DIR..."
    mkdir -p "$(dirname "$WORKTREE_DIR")"
    git -C "$REPO_DIR" worktree add "$WORKTREE_DIR" dev 2>&1
fi

while true; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Launching audit-qa worker..."

    # worktree를 dev 최신으로 동기화
    cd "$WORKTREE_DIR" || exit 1
    git fetch origin dev && git reset --hard origin/dev 2>/dev/null

    /usr/local/bin/claude -p "$(cat "$PROMPT_FILE")" \
        --max-turns 30 \
        --allowedTools "Bash,Read,Glob,Grep" \
        2>&1 | tee "/tmp/claude-audit-qa-$(date +%Y%m%d-%H%M%S).log"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Session ended. Next audit in ${POLL_INTERVAL}s..."
    sleep "$POLL_INTERVAL"
done
