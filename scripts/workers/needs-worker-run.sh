#!/bin/bash
# needs-worker-run.sh — loop+sleep 데몬. launchd KeepAlive로 유지.
# Phase 0: PR 케어 (BEHIND, dependabot, worktree 정리 — claude 불필요)
# Phase 1: needs-* 라벨 감지 → 해당 워커 발사
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="/Users/mark/workspace/minglit"
WORKTREE_BASE="/Users/mark/workspace/minglit-workers"
COMMON_FILE="$SCRIPT_DIR/prompts/worker-common.txt"
DIRECTION_FILE="$SCRIPT_DIR/prompts/direction.txt"
ISSUE_PROMPT="$SCRIPT_DIR/prompts/issue-worker.txt"
SESSION_TIMEOUT=3600
REPO="Mark-Yun/minglit"
LOG_DIR="/tmp/claude-worker-logs"
SLEEP_INTERVAL=600
MAX_CONCURRENT=6

mkdir -p "$LOG_DIR"

# 라벨 → 워커 매핑 (bash 3.2 호환 — 병렬 배열)
LABELS=(  "needs-arch"     "needs-uiux"     "needs-qa"     "needs-security"     "needs-legal"     "needs-pm"  "needs-tpm"  "needs-dev"      "needs-review")
WORKERS=( "audit-arch"     "audit-uiux"     "audit-qa"     "audit-security"     "audit-legal"     "pm-staff"  "tpm-staff"  "issue-worker"   "pr-reviewer")

# direction.txt를 사용하는 워커
STAFF_WORKERS="pm-staff tpm-staff"

# 종료 시 자식 프로세스 정리
cleanup() {
    kill $(jobs -p) 2>/dev/null
    wait 2>/dev/null
}
trap cleanup EXIT TERM INT

while true; do

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === needs-worker cycle ==="

# ============================================================
# Phase 0: PR 케어 (claude 세션 불필요)
# ============================================================

# 0a. 머지된 PR의 claude 세션 종료 + worktree 정리
for dir in "$WORKTREE_BASE"/issue-*; do
    [ -d "$dir" ] || continue
    issue_num="${dir##*issue-}"
    branch=$(git -C "$dir" branch --show-current 2>/dev/null || true)

    if [ -n "$branch" ] && [ "$branch" != "dev" ]; then
        pr_state=$(gh pr list --repo "$REPO" --head "$branch" --json state -q '.[0].state' 2>/dev/null || true)
        if [ "$pr_state" = "MERGED" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] PR merged for issue-${issue_num} — killing session + cleanup."
            pkill -f "/usr/local/bin/claude.*issue-${issue_num}" 2>/dev/null || true
            rm -rf "$dir"
            git -C "$REPO_DIR" worktree prune 2>/dev/null
            git -C "$REPO_DIR" branch -D "$branch" 2>/dev/null || true
            continue
        fi
    fi

    if ! pgrep -f "/usr/local/bin/claude.*issue-${issue_num}" >/dev/null 2>&1; then
        state=$(gh issue view "$issue_num" --repo "$REPO" --json state -q '.state' 2>/dev/null)
        if [ "$state" = "CLOSED" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cleaning up issue-${issue_num}..."
            rm -rf "$dir"
            git -C "$REPO_DIR" worktree prune 2>/dev/null
            [ -n "$branch" ] && [ "$branch" != "dev" ] && git -C "$REPO_DIR" branch -D "$branch" 2>/dev/null
        fi
    fi
done

# 0b. BEHIND PR → 브랜치 업데이트
behind_prs=$(gh pr list --repo "$REPO" --state open --json number,mergeStateStatus -q '[.[] | select(.mergeStateStatus == "BEHIND")] | .[].number' 2>/dev/null || true)
for pr_num in $behind_prs; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] PR #${pr_num} BEHIND — updating..."
    gh api "repos/${REPO}/pulls/${pr_num}/update-branch" --method PUT 2>/dev/null || true
done

# 0c. Dependabot PR → CI 통과 시 머지, 실패 시 close
dep_prs=$(gh pr list --repo "$REPO" --state open --json number,author -q '[.[] | select(.author.login == "dependabot[bot]")] | .[].number' 2>/dev/null || true)
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

# 0d. 내 PR → claude 세션으로 케어 (리뷰 대응) — 백그라운드 발사
my_prs=$(gh pr list --repo "$REPO" --author @me --state open --json number -q '.[].number' 2>/dev/null || true)
for pr_num in $my_prs; do
    head_branch=$(gh pr view "$pr_num" --repo "$REPO" --json headRefName -q '.headRefName' 2>/dev/null || true)
    issue_num=$(echo "$head_branch" | grep -oE '[0-9]+' | head -1 || true)
    [ -z "$issue_num" ] && continue
    pgrep -f "/usr/local/bin/claude.*issue-${issue_num}" >/dev/null 2>&1 && continue

    worktree_dir="$WORKTREE_BASE/issue-${issue_num}"
    if [ ! -d "$worktree_dir" ]; then
        git -C "$REPO_DIR" fetch origin "$head_branch" 2>/dev/null
        git -C "$REPO_DIR" worktree add "$worktree_dir" "origin/$head_branch" 2>/dev/null || true
    fi
    [ -d "$worktree_dir" ] || continue

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Caring for PR #${pr_num} (issue-${issue_num})..."
    (
        cd "$worktree_dir" || exit 1
        /usr/local/bin/claude -p "$(cat "$COMMON_FILE" 2>/dev/null)

$(cat "$ISSUE_PROMPT" 2>/dev/null)" \
            --max-turns 999 \
            --allowedTools "Bash,Read,Write,Edit,Glob,Grep,Agent" \
            2>&1 | tee "$LOG_DIR/issue-${issue_num}-$(date +%Y%m%d-%H%M%S).log"
    ) &
    worker_pid=$!
    ( sleep "$SESSION_TIMEOUT" && kill "$worker_pid" 2>/dev/null ) &
done

# ============================================================
# Phase 1: needs-* 라벨 감지 → 워커 발사
# ============================================================

active_count=$(pgrep -f "/usr/local/bin/claude" 2>/dev/null | wc -l | tr -d ' ') || active_count=0
if [ "$active_count" -ge "$MAX_CONCURRENT" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Max concurrent sessions ($MAX_CONCURRENT) reached. Skipping."
    sleep "$SLEEP_INTERVAL"
    continue
fi

found=0

for i in "${!LABELS[@]}"; do
    label="${LABELS[$i]}"
    worker="${WORKERS[$i]}"
    prompt_file="$SCRIPT_DIR/prompts/${worker}.txt"

    [ ! -f "$prompt_file" ] && continue

    # 이미 실행 중이면 스킵 (claude 명령줄에 워커 이름이 포함된 프로세스만 매칭)
    if pgrep -f "/usr/local/bin/claude.*${worker}" >/dev/null 2>&1; then
        continue
    fi

    count=$(gh issue list --repo "$REPO" --label "$label" --state open --json number -q 'length' 2>/dev/null || echo "0")
    [ "$count" -eq 0 ] && continue

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Found $count issue(s) with $label → launching $worker..."

    # staff 워커 여부 판별
    is_staff=false
    case " $STAFF_WORKERS " in *" $worker "*) is_staff=true ;; esac

    if $is_staff; then
        # staff 워커: repo dir에서 실행, direction.txt 포함
        (
            cd "$REPO_DIR" || exit 1
            /usr/local/bin/claude -p "$(cat "$DIRECTION_FILE" 2>/dev/null)

$(cat "$COMMON_FILE" 2>/dev/null)

$(cat "$prompt_file")" \
                --max-turns 999 \
                --allowedTools "Bash,Read,Write,Edit,Glob,Grep,Agent,WebSearch,WebFetch" \
                2>&1 | tee "$LOG_DIR/${worker}-$(date +%Y%m%d-%H%M%S).log"
        ) &
        worker_pid=$!
        ( sleep "$SESSION_TIMEOUT" && kill "$worker_pid" 2>/dev/null ) &
    elif [ "$worker" = "issue-worker" ]; then
        # issue-worker: worktree에서 실행 (이슈별 브랜치)
        issue_num=$(gh issue list --repo "$REPO" --label "$label" --state open \
            --json number,assignees,labels \
            -q '[.[] | select(.assignees | length == 0) |
                {number, priority: (
                    if (.labels | map(.name) | any(. == "P0-critical")) then 0
                    elif (.labels | map(.name) | any(. == "P1-high")) then 1
                    elif (.labels | map(.name) | any(. == "P2-medium")) then 2
                    elif (.labels | map(.name) | any(. == "P3-low")) then 3
                    else 4 end
                )}] | sort_by(.priority, .number) | .[0].number // empty')
        if [ -n "${issue_num:-}" ]; then
            worktree_dir="$WORKTREE_BASE/issue-${issue_num}"
            if [ ! -d "$worktree_dir" ]; then
                mkdir -p "$WORKTREE_BASE"
                git -C "$REPO_DIR" fetch origin dev 2>/dev/null
                git -C "$REPO_DIR" worktree add "$worktree_dir" -b "fix/issue-${issue_num}" origin/dev 2>/dev/null
            fi
            (
                cd "$worktree_dir" || exit 1
                git fetch origin dev 2>/dev/null
                git diff --quiet && git diff --cached --quiet && git merge origin/dev --no-edit 2>/dev/null || true
                /usr/local/bin/claude -p "$(cat "$COMMON_FILE" 2>/dev/null)

$(cat "$prompt_file")" \
                    --max-turns 999 \
                    --allowedTools "Bash,Read,Write,Edit,Glob,Grep,Agent" \
                    2>&1 | tee "$LOG_DIR/issue-${issue_num}-$(date +%Y%m%d-%H%M%S).log"
            ) &
            worker_pid=$!
            ( sleep "$SESSION_TIMEOUT" && kill "$worker_pid" 2>/dev/null ) &
        fi
    else
        # audit/review 워커: 공용 worktree에서 실행
        worktree_dir="$WORKTREE_BASE/$worker"
        if [ ! -d "$worktree_dir" ]; then
            mkdir -p "$WORKTREE_BASE"
            git -C "$REPO_DIR" worktree add --detach "$worktree_dir" origin/dev 2>&1
        fi
        (
            cd "$worktree_dir" || exit 1
            git fetch origin dev && git reset --hard origin/dev 2>/dev/null
            /usr/local/bin/claude -p "$(cat "$COMMON_FILE" 2>/dev/null)

$(cat "$prompt_file")" \
                --max-turns 999 \
                --allowedTools "Bash,Read,Write,Edit,Glob,Grep,Agent,WebSearch,WebFetch" \
                2>&1 | tee "$LOG_DIR/${worker}-$(date +%Y%m%d-%H%M%S).log"
        ) &
        worker_pid=$!
        ( sleep "$SESSION_TIMEOUT" && kill "$worker_pid" 2>/dev/null ) &
    fi

    found=$((found + 1))
done

if [ "$found" -gt 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Launched $found worker(s)."
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] No needs-* labels found."
fi

sleep "$SLEEP_INTERVAL"
done
