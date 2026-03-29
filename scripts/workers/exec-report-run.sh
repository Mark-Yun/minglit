#!/bin/bash
# exec-report-run.sh — 주간 경영 리포트 (주 1회)
# pm-staff → tpm-staff 순차 실행. report-exec 라벨로 이슈 생성.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="/Users/mark/workspace/minglit"
COMMON_FILE="$SCRIPT_DIR/prompts/worker-common.txt"
DIRECTION_FILE="$SCRIPT_DIR/prompts/direction.txt"
SESSION_TIMEOUT=3600
LOG_DIR="/tmp/claude-worker-logs"

mkdir -p "$LOG_DIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === Exec report cycle starting ==="

# --- PM Staff ---
pm_prompt="$SCRIPT_DIR/prompts/pm-staff.txt"
if [ -f "$pm_prompt" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running pm-staff..."
    cd "$REPO_DIR" || exit 1

    /usr/local/bin/claude -p "$(cat "$DIRECTION_FILE" 2>/dev/null)

$(cat "$COMMON_FILE" 2>/dev/null)

$(cat "$pm_prompt")" \
        --max-turns 999 \
        --allowedTools "Bash,Read,Write,Edit,Glob,Grep,Agent,WebSearch,WebFetch" \
        2>&1 | tee "$LOG_DIR/pm-staff-$(date +%Y%m%d-%H%M%S).log" &
    claude_pid=$!
    ( sleep "$SESSION_TIMEOUT" && kill "$claude_pid" 2>/dev/null ) &
    timer_pid=$!
    wait "$claude_pid" 2>/dev/null
    kill "$timer_pid" 2>/dev/null; wait "$timer_pid" 2>/dev/null

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] pm-staff done."
fi

# --- TPM Staff ---
tpm_prompt="$SCRIPT_DIR/prompts/tpm-staff.txt"
if [ -f "$tpm_prompt" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Running tpm-staff..."
    cd "$REPO_DIR" || exit 1

    /usr/local/bin/claude -p "$(cat "$DIRECTION_FILE" 2>/dev/null)

$(cat "$COMMON_FILE" 2>/dev/null)

$(cat "$tpm_prompt")" \
        --max-turns 999 \
        --allowedTools "Bash,Read,Write,Edit,Glob,Grep,Agent,WebSearch,WebFetch" \
        2>&1 | tee "$LOG_DIR/tpm-staff-$(date +%Y%m%d-%H%M%S).log" &
    claude_pid=$!
    ( sleep "$SESSION_TIMEOUT" && kill "$claude_pid" 2>/dev/null ) &
    timer_pid=$!
    wait "$claude_pid" 2>/dev/null
    kill "$timer_pid" 2>/dev/null; wait "$timer_pid" 2>/dev/null

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] tpm-staff done."
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === Exec report cycle complete ==="
