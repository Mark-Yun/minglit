#!/bin/bash
# issue-worker-claude.sh — 이슈별 git worktree 격리 + 10분 단위 폴링
#
# 설계:
#   - gh CLI로 할 일이 있는지 먼저 확인 (토큰 절약)
#   - 할 일 있을 때만 claude 세션 시작
#   - 이슈별 전용 git worktree 생성 (issue-{번호})
#   - PR 머지 후 worktree 자동 정리
#   - 상태는 GitHub 이슈/PR 코멘트에 저장 (AI 메모리 의존 X)
#   - claude -p hang 방지: 30분 타임아웃
#   - 연속 빈 세션 감지: 3회 시 30분 쿨다운

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="/Users/mark/workspace/minglit"
WORKTREE_BASE="/Users/mark/workspace/minglit-workers"
PROMPT_FILE="$SCRIPT_DIR/prompts/issue-worker.txt"
POLL_INTERVAL=600      # 10분
SESSION_TIMEOUT=1800   # 30분 — claude -p hang 방지
COOLDOWN_INTERVAL=1800 # 30분 — 연속 빈 세션 시 쿨다운
MAX_EMPTY_SESSIONS=3   # 연속 빈 세션 허용 횟수
REPO="Mark-Yun/minglit"
LOG_DIR="/tmp/claude-worker-logs"

mkdir -p "$LOG_DIR"

if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: Prompt file not found: $PROMPT_FILE"
    exit 1
fi

EMPTY_COUNT=0

# ============================================================
# claude 세션 실행 (타임아웃 + 빈 세션 감지)
# ============================================================
run_claude_session() {
    local issue_num="$1"
    local log_file="$LOG_DIR/issue-${issue_num}-$(date +%Y%m%d-%H%M%S).log"

    # macOS에 timeout 없으므로 백그라운드 + wait로 대체
    /usr/local/bin/claude -p "$(cat "$PROMPT_FILE")" \
        --max-turns 999 \
        --allowedTools "Bash,Read,Write,Edit,Glob,Grep" \
        2>&1 | tee "$log_file" &
    local claude_pid=$!
    ( sleep "$SESSION_TIMEOUT" && kill "$claude_pid" 2>/dev/null && echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⏰ Session timed out after ${SESSION_TIMEOUT}s for issue #${issue_num}" ) &
    local timer_pid=$!
    wait "$claude_pid" 2>/dev/null
    kill "$timer_pid" 2>/dev/null
    wait "$timer_pid" 2>/dev/null

    # 빈 세션 감지
    if [ ! -s "$log_file" ]; then
        EMPTY_COUNT=$((EMPTY_COUNT + 1))
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ Empty session #${EMPTY_COUNT}/${MAX_EMPTY_SESSIONS} for issue #${issue_num}"
        if [ "$EMPTY_COUNT" -ge "$MAX_EMPTY_SESSIONS" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🛑 ${MAX_EMPTY_SESSIONS} consecutive empty sessions. Cooling down ${COOLDOWN_INTERVAL}s..."
            sleep "$COOLDOWN_INTERVAL"
            EMPTY_COUNT=0
        fi
    else
        EMPTY_COUNT=0
    fi
}

# ============================================================
# 머지된 이슈 worktree 정리
# ============================================================
cleanup_merged_worktrees() {
    for dir in "$WORKTREE_BASE"/issue-*; do
        [ -d "$dir" ] || continue
        issue_num="${dir##*issue-}"

        # 이슈가 닫혔는지 확인
        state=$(gh issue view "$issue_num" --repo "$REPO" --json state -q '.state' 2>/dev/null)
        if [ "$state" = "CLOSED" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Cleaning up worktree for closed issue #${issue_num}..."
            # 로컬 브랜치 이름 확인
            branch=$(git -C "$dir" branch --show-current 2>/dev/null)
            # worktree 제거
            rm -rf "$dir"
            git -C "$REPO_DIR" worktree prune 2>/dev/null
            # 로컬 브랜치 삭제
            if [ -n "$branch" ] && [ "$branch" != "dev" ]; then
                git -C "$REPO_DIR" branch -D "$branch" 2>/dev/null
            fi
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Cleaned up issue-${issue_num} (${branch})"
        fi
    done
}

# ============================================================
# 진행 중인 PR 케어 (ai-worker 라벨)
# ============================================================
care_open_prs() {
    local prs
    prs=$(gh pr list --repo "$REPO" --label ai-worker --state open --json number -q '.[].number')
    [ -z "$prs" ] && return 1

    for pr_num in $prs; do
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Caring for PR #${pr_num}..."

        # PR의 브랜치에서 이슈 번호 추출
        head_branch=$(gh pr view "$pr_num" --repo "$REPO" --json headRefName -q '.headRefName')
        issue_num=$(echo "$head_branch" | grep -oE '[0-9]+' | head -1)
        worktree_dir="$WORKTREE_BASE/issue-${issue_num}"

        if [ ! -d "$worktree_dir" ]; then
            # worktree가 없으면 생성
            git -C "$REPO_DIR" fetch origin "$head_branch" 2>/dev/null
            git -C "$REPO_DIR" worktree add "$worktree_dir" -b "$head_branch" "origin/$head_branch" 2>/dev/null || \
            git -C "$REPO_DIR" worktree add "$worktree_dir" "origin/$head_branch" 2>/dev/null
        fi

        cd "$worktree_dir" || continue

        run_claude_session "$issue_num"
    done

    return 0
}

# ============================================================
# 새 이슈 처리 (미assign, 1개씩)
# ============================================================
work_new_issue() {
    # 미assign 이슈 중 우선순위 높은 것 1개 (P0 > P1 > P2 > P3 > none)
    local issue_num
    issue_num=$(gh issue list --repo "$REPO" --state open \
        --json number,assignees,labels \
        -q '[.[] | select(.assignees | length == 0) |
            {number, priority: (
                if (.labels | map(.name) | any(. == "P0-critical")) then 0
                elif (.labels | map(.name) | any(. == "P1-high")) then 1
                elif (.labels | map(.name) | any(. == "P2-medium")) then 2
                elif (.labels | map(.name) | any(. == "P3-low")) then 3
                else 4 end
            )}] | sort_by(.priority, .number) | .[0].number // empty')

    [ -z "$issue_num" ] && return 1

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Working on issue #${issue_num}..."

    local worktree_dir="$WORKTREE_BASE/issue-${issue_num}"

    # 이슈별 worktree 생성 (없으면)
    if [ ! -d "$worktree_dir" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Creating worktree: issue-${issue_num}"
        mkdir -p "$WORKTREE_BASE"
        git -C "$REPO_DIR" fetch origin dev 2>/dev/null
        git -C "$REPO_DIR" worktree add "$worktree_dir" -b "fix/issue-${issue_num}" origin/dev 2>/dev/null
    else
        # 기존 worktree — dev 최신 반영
        cd "$worktree_dir" || return 1
        git fetch origin dev 2>/dev/null
        # 커밋 안 된 변경이 있으면 reset 안 함
        if git diff --quiet && git diff --cached --quiet; then
            git merge origin/dev --no-edit 2>/dev/null || true
        fi
    fi

    cd "$worktree_dir" || return 1

    run_claude_session "$issue_num"

    return 0
}

# ============================================================
# 메인 루프
# ============================================================
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Issue worker started (poll: ${POLL_INTERVAL}s, timeout: ${SESSION_TIMEOUT}s)"

while true; do
    # 1. 머지된 worktree 정리
    cleanup_merged_worktrees

    # 2. 진행 중인 PR 케어 (우선)
    if care_open_prs; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] PR care done. Next cycle in ${POLL_INTERVAL}s..."
        sleep "$POLL_INTERVAL"
        continue
    fi

    # 3. 새 이슈 작업
    if work_new_issue; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Issue work done. Next cycle in ${POLL_INTERVAL}s..."
        sleep "$POLL_INTERVAL"
        continue
    fi

    # 4. 할 일 없음
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] No work found. Sleeping..."
    sleep "$POLL_INTERVAL"
done
