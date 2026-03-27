#!/bin/bash
# issue-worker-run.sh — 단발성 실행. launchd가 주기적으로 호출.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="/Users/mark/workspace/minglit"
WORKTREE_BASE="/Users/mark/workspace/minglit-workers"
PROMPT_FILE="$SCRIPT_DIR/prompts/issue-worker.txt"
SESSION_TIMEOUT=3600
REPO="Mark-Yun/minglit"
LOG_DIR="/tmp/claude-worker-logs"

mkdir -p "$LOG_DIR"
[ ! -f "$PROMPT_FILE" ] && echo "Error: Prompt not found" && exit 1


# --- 타이머 정리를 위한 trap ---
cleanup() { [ -n "${timer_pid:-}" ] && kill "$timer_pid" 2>/dev/null && wait "$timer_pid" 2>/dev/null; }
trap cleanup EXIT

# --- 머지된 worktree 정리 ---
for dir in "$WORKTREE_BASE"/issue-*; do
    [ -d "$dir" ] || continue
    issue_num="${dir##*issue-}"
    # worktree가 현재 사용 중이면 건너뛰기
    if pgrep -f "$dir" >/dev/null 2>&1; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Skipping issue-${issue_num} — process active."
        continue
    fi
    state=$(gh issue view "$issue_num" --repo "$REPO" --json state -q '.state' 2>/dev/null)
    if [ "$state" = "CLOSED" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cleaning up issue-${issue_num}..."
        branch=$(git -C "$dir" branch --show-current 2>/dev/null)
        rm -rf "$dir"
        git -C "$REPO_DIR" worktree prune 2>/dev/null
        [ -n "$branch" ] && [ "$branch" != "dev" ] && git -C "$REPO_DIR" branch -D "$branch" 2>/dev/null
    fi
done

# --- PR 케어 (내가 만든 PR) ---
prs=$(gh pr list --repo "$REPO" --author @me --state open --json number -q '.[].number')
if [ -n "$prs" ]; then
    for pr_num in $prs; do
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Caring for PR #${pr_num}..."
        head_branch=$(gh pr view "$pr_num" --repo "$REPO" --json headRefName -q '.headRefName')
        issue_num=$(echo "$head_branch" | grep -oE '[0-9]+' | head -1 || true)
        # 이슈 번호 추출 실패 시 건너뛰기
        if [ -z "$issue_num" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cannot extract issue number from branch '${head_branch}'. Skipping."
            continue
        fi
        worktree_dir="$WORKTREE_BASE/issue-${issue_num}"
        if [ ! -d "$worktree_dir" ]; then
            git -C "$REPO_DIR" fetch origin "$head_branch" 2>/dev/null
            git -C "$REPO_DIR" worktree add "$worktree_dir" "origin/$head_branch" 2>/dev/null || true
        fi
        cd "$worktree_dir" 2>/dev/null || continue
        /usr/local/bin/claude -p "$(cat "$PROMPT_FILE")" \
            --max-turns 999 \
            --allowedTools "Bash,Read,Write,Edit,Glob,Grep,Agent" \
            2>&1 | tee "$LOG_DIR/issue-${issue_num}-$(date +%Y%m%d-%H%M%S).log" &
        local_pid=$!
        ( sleep "$SESSION_TIMEOUT" && kill "$claude_pid" 2>/dev/null ) &
        timer_pid=$!
        wait "$local_pid" 2>/dev/null
        kill "$timer_pid" 2>/dev/null; wait "$timer_pid" 2>/dev/null
        timer_pid=""
    done
fi

# --- 새 이슈 처리 (actionable 라벨만) ---
issue_num=$(gh issue list --repo "$REPO" --state open \
    --json number,assignees,labels \
    -q '[.[] | select(.assignees | length == 0) |
        select(.labels | map(.name) | any(. == "bug-report" or . == "bug" or . == "ci-failure" or . == "enhancement" or . == "refactor")) |
        {number, priority: (
            if (.labels | map(.name) | any(. == "P0-critical")) then 0
            elif (.labels | map(.name) | any(. == "P1-high")) then 1
            elif (.labels | map(.name) | any(. == "P2-medium")) then 2
            elif (.labels | map(.name) | any(. == "P3-low")) then 3
            else 4 end
        )}] | sort_by(.priority, .number) | .[0].number // empty')

[ -z "$issue_num" ] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] No work found." && exit 0

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Working on issue #${issue_num}..."
worktree_dir="$WORKTREE_BASE/issue-${issue_num}"

if [ ! -d "$worktree_dir" ]; then
    mkdir -p "$WORKTREE_BASE"
    git -C "$REPO_DIR" fetch origin dev 2>/dev/null
    git -C "$REPO_DIR" worktree add "$worktree_dir" -b "fix/issue-${issue_num}" origin/dev 2>/dev/null
else
    cd "$worktree_dir"
    git fetch origin dev 2>/dev/null
    git diff --quiet && git diff --cached --quiet && git merge origin/dev --no-edit 2>/dev/null || true
fi

cd "$worktree_dir" || exit 1

/usr/local/bin/claude -p "$(cat "$PROMPT_FILE")" \
    --max-turns 999 \
    --allowedTools "Bash,Read,Write,Edit,Glob,Grep,Agent" \
    2>&1 | tee "$LOG_DIR/issue-${issue_num}-$(date +%Y%m%d-%H%M%S).log" &
claude_pid=$!
( sleep "$SESSION_TIMEOUT" && kill "$claude_pid" 2>/dev/null ) &
timer_pid=$!
wait "$claude_pid" 2>/dev/null
kill "$timer_pid" 2>/dev/null; wait "$timer_pid" 2>/dev/null
timer_pid=""
