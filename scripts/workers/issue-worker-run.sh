#!/bin/bash
# issue-worker-run.sh — loop+sleep 데몬. launchd KeepAlive로 유지.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="/Users/mark/workspace/minglit"
WORKTREE_BASE="/Users/mark/workspace/minglit-workers"
PROMPT_FILE="$SCRIPT_DIR/prompts/issue-worker.txt"
COMMON_FILE="$SCRIPT_DIR/prompts/worker-common.txt"
SESSION_TIMEOUT=3600
REPO="Mark-Yun/minglit"
LOG_DIR="/tmp/claude-worker-logs"
SLEEP_INTERVAL=600
MAX_CONCURRENT=6

mkdir -p "$LOG_DIR"
[ ! -f "$PROMPT_FILE" ] && echo "Error: Prompt not found" && exit 1

while true; do

# --- 머지된 PR의 claude 세션 종료 + worktree 정리 ---
for dir in "$WORKTREE_BASE"/issue-*; do
    [ -d "$dir" ] || continue
    issue_num="${dir##*issue-}"
    branch=$(git -C "$dir" branch --show-current 2>/dev/null || true)

    # PR이 머지됐으면 claude 세션 kill + worktree 정리
    if [ -n "$branch" ] && [ "$branch" != "dev" ]; then
        pr_state=$(gh pr list --repo "$REPO" --head "$branch" --json state -q '.[0].state' 2>/dev/null || true)
        if [ "$pr_state" = "MERGED" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] PR merged for issue-${issue_num} — killing claude session + cleanup."
            pkill -f "issue-${issue_num}" 2>/dev/null || true
            rm -rf "$dir"
            git -C "$REPO_DIR" worktree prune 2>/dev/null
            git -C "$REPO_DIR" branch -D "$branch" 2>/dev/null || true
            continue
        fi
    fi

    # 이슈가 닫혔으면 (PR 없이 닫힌 경우) 동일 정리
    if ! pgrep -f "$dir" >/dev/null 2>&1; then
        state=$(gh issue view "$issue_num" --repo "$REPO" --json state -q '.state' 2>/dev/null)
        if [ "$state" = "CLOSED" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cleaning up issue-${issue_num}..."
            rm -rf "$dir"
            git -C "$REPO_DIR" worktree prune 2>/dev/null
            [ -n "$branch" ] && [ "$branch" != "dev" ] && git -C "$REPO_DIR" branch -D "$branch" 2>/dev/null
        fi
    fi
done

# --- 동시 실행 세션 수 제한 ---
active_count=$(pgrep -f "/usr/local/bin/claude" | wc -l | tr -d ' ')
if [ "$active_count" -ge "$MAX_CONCURRENT" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Max concurrent sessions ($MAX_CONCURRENT) reached. Skipping this cycle."
    sleep "$SLEEP_INTERVAL"
    continue
fi

# --- PR 케어 (전체 열린 PR) ---

# 1. BEHIND PR → 브랜치 업데이트 (claude 불필요)
behind_prs=$(gh pr list --repo "$REPO" --state open --json number,mergeStateStatus -q '[.[] | select(.mergeStateStatus == "BEHIND")] | .[].number')
for pr_num in $behind_prs; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] PR #${pr_num} BEHIND — updating..."
    gh api "repos/${REPO}/pulls/${pr_num}/update-branch" --method PUT 2>/dev/null || true
done

# 2. Dependabot PR → CI 통과 시 머지, 실패 시 close
dep_prs=$(gh pr list --repo "$REPO" --state open --json number,author -q '[.[] | select(.author.login | startswith("app/"))] | .[].number')
for pr_num in $dep_prs; do
    fail_count=$(gh pr checks "$pr_num" --repo "$REPO" 2>&1 | grep -v "pass\|skipped" | grep -c "fail" || echo "0")
    if [ "$fail_count" = "0" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Dependabot PR #${pr_num} — merging..."
        gh pr merge "$pr_num" --repo "$REPO" --squash 2>/dev/null || true
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Dependabot PR #${pr_num} — CI failed, closing..."
        gh pr close "$pr_num" --repo "$REPO" --comment "🤖 CI 실패로 자동 close." 2>/dev/null || true
    fi
done

# 3. 내 PR → claude 세션으로 케어 (리뷰 대응 등) — 백그라운드 발사
my_prs=$(gh pr list --repo "$REPO" --author @me --state open --json number -q '.[].number')
for pr_num in $my_prs; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Caring for my PR #${pr_num}..."
    head_branch=$(gh pr view "$pr_num" --repo "$REPO" --json headRefName -q '.headRefName')
    issue_num=$(echo "$head_branch" | grep -oE '[0-9]+' | head -1 || true)
    # Fix #674: 이슈번호 없는 브랜치도 PR번호로 worktree 생성
    if [ -z "$issue_num" ]; then
        worktree_id="pr-${pr_num}"
    else
        worktree_id="issue-${issue_num}"
    fi
    # 중복 실행 방지: 해당 worktree가 이미 처리 중이면 스킵
    if pgrep -f "${worktree_id}" >/dev/null 2>&1; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${worktree_id} already in progress. Skipping PR care."
        continue
    fi
    worktree_dir="$WORKTREE_BASE/${worktree_id}"
    if [ ! -d "$worktree_dir" ]; then
        git -C "$REPO_DIR" fetch origin "$head_branch" 2>/dev/null
        git -C "$REPO_DIR" worktree add "$worktree_dir" "origin/$head_branch" 2>/dev/null || true
    fi
    cd "$worktree_dir" 2>/dev/null || continue
    /usr/local/bin/claude -p "$(cat "$COMMON_FILE" 2>/dev/null)

$(cat "$PROMPT_FILE")" \
        --max-turns 999 \
        --allowedTools "Bash,Read,Write,Edit,Glob,Grep,Agent" \
        2>&1 | tee "$LOG_DIR/${worktree_id}-$(date +%Y%m%d-%H%M%S).log" &
    local_pid=$!
    ( sleep "$SESSION_TIMEOUT" && kill "$local_pid" 2>/dev/null ) &
    # 백그라운드 발사 — wait 없이 다음으로 진행
done

# --- 새 이슈 처리 (needs-dev 라벨만) ---
issue_num=$(gh issue list --repo "$REPO" --label "needs-dev" --state open \
    --json number,assignees,labels \
    -q '[.[] | select(.assignees | length == 0) |
        {number, priority: (
            if (.labels | map(.name) | any(. == "P0-critical")) then 0
            elif (.labels | map(.name) | any(. == "P1-high")) then 1
            elif (.labels | map(.name) | any(. == "P2-medium")) then 2
            elif (.labels | map(.name) | any(. == "P3-low")) then 3
            else 4 end
        )}] | sort_by(.priority, .number) | .[0].number // empty')

if [ -z "${issue_num:-}" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] No work found."
    sleep "$SLEEP_INTERVAL"
    continue
fi

# 중복 실행 방지: 해당 이슈가 이미 처리 중이면 스킵
if pgrep -f "issue-${issue_num}" >/dev/null 2>&1; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Issue #${issue_num} already in progress. Skipping."
    sleep "$SLEEP_INTERVAL"
    continue
fi

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

cd "$worktree_dir" || { sleep "$SLEEP_INTERVAL"; continue; }

/usr/local/bin/claude -p "$(cat "$COMMON_FILE" 2>/dev/null)

$(cat "$PROMPT_FILE")" \
    --max-turns 999 \
    --allowedTools "Bash,Read,Write,Edit,Glob,Grep,Agent" \
    2>&1 | tee "$LOG_DIR/issue-${issue_num}-$(date +%Y%m%d-%H%M%S).log" &
local_pid=$!
( sleep "$SESSION_TIMEOUT" && kill "$local_pid" 2>/dev/null ) &
# 백그라운드 발사 — wait 없이 다음 사이클로

sleep "$SLEEP_INTERVAL"
done
