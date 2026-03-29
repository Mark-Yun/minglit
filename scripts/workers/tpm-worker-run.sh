#!/bin/bash
# tpm-worker-run.sh — 단발성. launchd StartInterval(30분)으로 호출.
# audit-report 분석 → actionable 이슈 생성 + needs-tpm 라벨 대응.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="/Users/mark/workspace/minglit"
PROMPT_FILE="$SCRIPT_DIR/prompts/tpm-staff.txt"
DIRECTION_FILE="$SCRIPT_DIR/prompts/direction.txt"
COMMON_FILE="$SCRIPT_DIR/prompts/worker-common.txt"
SESSION_TIMEOUT=3600
REPO="Mark-Yun/minglit"
LOG_DIR="/tmp/claude-worker-logs"

mkdir -p "$LOG_DIR"
[ ! -f "$PROMPT_FILE" ] && echo "Error: Prompt not found" && exit 1

# 처리할 게 없으면 즉시 종료 (토큰 절약)
audit_reports=$(gh issue list --repo "$REPO" --label "audit-report" --state open --json number -q 'length' 2>/dev/null || echo "0")
needs_tpm=$(gh issue list --repo "$REPO" --label "needs-tpm" --state open --json number -q 'length' 2>/dev/null || echo "0")

if [ "$audit_reports" -eq 0 ] && [ "$needs_tpm" -eq 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] No audit-report or needs-tpm issues. Exiting."
    exit 0
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] TPM worker starting (audit-report: $audit_reports, needs-tpm: $needs_tpm)..."

cd "$REPO_DIR" || exit 1

/usr/local/bin/claude -p "$(cat "$DIRECTION_FILE" 2>/dev/null)

$(cat "$COMMON_FILE" 2>/dev/null)

$(cat "$PROMPT_FILE")" \
    --max-turns 999 \
    --allowedTools "Bash,Read,Write,Edit,Glob,Grep,Agent,WebSearch,WebFetch" \
    2>&1 | tee "$LOG_DIR/tpm-worker-$(date +%Y%m%d-%H%M%S).log" &
claude_pid=$!
( sleep "$SESSION_TIMEOUT" && kill "$claude_pid" 2>/dev/null ) &
timer_pid=$!
wait "$claude_pid" 2>/dev/null
kill "$timer_pid" 2>/dev/null; wait "$timer_pid" 2>/dev/null

echo "[$(date '+%Y-%m-%d %H:%M:%S')] TPM worker done."
