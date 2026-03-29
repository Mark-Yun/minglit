#!/bin/bash
# audit-report-run.sh — 정기 감사 리포트 생성 (주 2회, 월/목)
# 5개 감사 워커를 순차 실행하여 audit-report 이슈를 생성한다.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="/Users/mark/workspace/minglit"
WORKTREE_BASE="/Users/mark/workspace/minglit-workers"
COMMON_FILE="$SCRIPT_DIR/prompts/worker-common.txt"
SESSION_TIMEOUT=3600
LOG_DIR="/tmp/claude-worker-logs"

mkdir -p "$LOG_DIR"

AUDITORS=(audit-arch audit-qa audit-security audit-uiux audit-legal)

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === Audit report cycle starting ==="

for auditor in "${AUDITORS[@]}"; do
    prompt_file="$SCRIPT_DIR/prompts/${auditor}.txt"
    worktree_dir="$WORKTREE_BASE/$auditor"

    if [ ! -f "$prompt_file" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ Prompt not found: $prompt_file — skipping $auditor"
        continue
    fi

    # worktree 준비
    if [ ! -d "$worktree_dir" ]; then
        mkdir -p "$WORKTREE_BASE"
        git -C "$REPO_DIR" worktree add --detach "$worktree_dir" origin/dev 2>&1
    fi
    cd "$worktree_dir" || continue
    git fetch origin dev && git reset --hard origin/dev 2>/dev/null

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running $auditor..."

    /usr/local/bin/claude -p "$(cat "$COMMON_FILE" 2>/dev/null)

$(cat "$prompt_file")" \
        --max-turns 999 \
        --allowedTools "Bash,Read,Write,Edit,Glob,Grep,Agent,WebSearch,WebFetch" \
        2>&1 | tee "$LOG_DIR/${auditor}-$(date +%Y%m%d-%H%M%S).log" &
    claude_pid=$!
    ( sleep "$SESSION_TIMEOUT" && kill "$claude_pid" 2>/dev/null ) &
    timer_pid=$!
    wait "$claude_pid" 2>/dev/null
    kill "$timer_pid" 2>/dev/null; wait "$timer_pid" 2>/dev/null

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $auditor done."
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === Audit report cycle complete ==="
