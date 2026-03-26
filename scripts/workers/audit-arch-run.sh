#!/bin/bash
# audit-arch-run.sh — 단발성. launchd가 24시간마다 호출.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="/Users/mark/workspace/minglit"
WORKTREE_DIR="/Users/mark/workspace/minglit-workers/audit-arch"
PROMPT_FILE="$SCRIPT_DIR/prompts/audit-arch.txt"
REPO="Mark-Yun/minglit"

[ ! -f "$PROMPT_FILE" ] && echo "Error: Prompt not found" && exit 1

# Worktree 초기화
if [ ! -d "$WORKTREE_DIR" ]; then
    mkdir -p "$(dirname "$WORKTREE_DIR")"
    git -C "$REPO_DIR" worktree add --detach "$WORKTREE_DIR" origin/dev 2>&1
fi

cd "$WORKTREE_DIR" || exit 1
git fetch origin dev && git reset --hard origin/dev 2>/dev/null

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running audit-arch..."

/usr/local/bin/claude -p "$(cat "$PROMPT_FILE")" \
    --max-turns 30 \
    --allowedTools "Bash,Read,Write,Edit,Glob,Grep" \
    2>&1 | tee "/tmp/claude-audit-arch-$(date +%Y%m%d-%H%M%S).log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] audit-arch done."
