#!/bin/bash
# pr-care-claude.sh — 2시간 이상 케어 없는 PR을 감지하고 claude로 케어
#
# 설계:
#   - 모든 열린 PR을 스캔 (ai-worker 라벨 무관)
#   - 2시간 이상 업데이트 없는 BEHIND/BLOCKED/미머지 PR 대상
#   - dependabot PR: CI 통과 시 자동 머지, 실패 시 close
#   - 일반 PR: 코드리뷰 코멘트 대응, BEHIND 업데이트
#   - 1사이클에 PR 1개씩 처리
#   - claude -p 30분 타임아웃

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="/Users/mark/workspace/minglit"
PROMPT_FILE="$SCRIPT_DIR/prompts/pr-care-worker.txt"
POLL_INTERVAL=1800     # 30분
SESSION_TIMEOUT=1800   # 30분
STALE_THRESHOLD=1800   # 30분 (초)
REPO="Mark-Yun/minglit"
LOG_DIR="/tmp/claude-pr-care-logs"

mkdir -p "$LOG_DIR"

if [ ! -f "$PROMPT_FILE" ]; then
    echo "Error: Prompt file not found: $PROMPT_FILE"
    exit 1
fi

# ============================================================
# 케어가 필요한 PR 찾기 (2시간 이상 업데이트 없음)
# ============================================================
find_stale_pr() {
    local now
    now=$(date +%s)

    # 모든 열린 PR 조회 (updatedAt 포함)
    local pr_json
    pr_json=$(gh pr list --repo "$REPO" --state open \
        --json number,title,updatedAt,mergeStateStatus,author,labels,autoMergeRequest \
        -q '.')

    # 2시간 이상 업데이트 없는 PR 중 가장 오래된 것
    echo "$pr_json" | python3 -c "
import sys, json
from datetime import datetime, timezone

now = datetime.now(timezone.utc)
threshold = $STALE_THRESHOLD

try:
    prs = json.load(sys.stdin)
except:
    sys.exit(1)

stale = []
for pr in prs:
    updated = datetime.fromisoformat(pr['updatedAt'].replace('Z', '+00:00'))
    age_sec = (now - updated).total_seconds()
    if age_sec >= threshold:
        stale.append({
            'number': pr['number'],
            'title': pr['title'],
            'age_hours': round(age_sec / 3600, 1),
            'status': pr['mergeStateStatus'],
            'author': pr['author']['login'],
            'is_bot': pr['author']['login'].startswith('app/'),
            'auto_merge': pr.get('autoMergeRequest') is not None,
        })

if not stale:
    sys.exit(1)

# 우선순위: BEHIND > BLOCKED > 기타, 오래된 순
stale.sort(key=lambda x: (-({'BEHIND': 2, 'BLOCKED': 1}.get(x['status'], 0)), -x['age_hours']))
for s in stale:
    print(s['number'])
" 2>/dev/null
}

# ============================================================
# PR 케어 실행
# ============================================================
care_pr() {
    local pr_num="$1"
    local log_file="$LOG_DIR/pr-${pr_num}-$(date +%Y%m%d-%H%M%S).log"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Caring for PR #${pr_num}..."

    # BEHIND는 claude 없이 바로 처리
    local status
    status=$(gh pr view "$pr_num" --repo "$REPO" --json mergeStateStatus -q '.mergeStateStatus')
    if [ "$status" = "BEHIND" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] PR #${pr_num} is BEHIND — updating branch..."
        gh api "repos/${REPO}/pulls/${pr_num}/update-branch" --method PUT 2>&1 | tee "$log_file"
        return 0
    fi

    # dependabot PR — CI 통과 시 자동 머지
    local author
    author=$(gh pr view "$pr_num" --repo "$REPO" --json author -q '.author.login')
    if [[ "$author" == app/dependabot* ]]; then
        local all_passed
        all_passed=$(gh pr checks "$pr_num" --repo "$REPO" 2>&1 | grep -v "pass\|skipped" | grep -c "fail" || echo "0")
        if [ "$all_passed" = "0" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Dependabot PR #${pr_num} — CI passed, merging..."
            gh pr merge "$pr_num" --repo "$REPO" --squash 2>&1 | tee "$log_file"
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Dependabot PR #${pr_num} — CI failed, closing..."
            gh pr close "$pr_num" --repo "$REPO" --comment "🤖 PR Care: CI 실패로 자동 close. Dependabot이 다음 버전에서 재시도합니다." 2>&1 | tee -a "$log_file"
        fi
        return 0
    fi

    # 나머지: claude로 케어 (코드리뷰 대응, conflict 해결 등)
    cd "$REPO_DIR" || return 1

    local pr_context
    pr_context=$(cat <<CONTEXT
PR #${pr_num} 케어가 필요합니다.

상태: ${status}
작성자: ${author}

아래 순서로 확인하고 처리해주세요:
1. gh pr checks ${pr_num} 로 CI 상태 확인
2. gh api repos/${REPO}/pulls/${pr_num}/comments 로 미해결 리뷰 코멘트 확인
3. gh pr view ${pr_num} --json mergeStateStatus 로 머지 상태 확인
4. BEHIND → gh api repos/${REPO}/pulls/${pr_num}/update-branch --method PUT
5. 리뷰 코멘트가 있으면 대응 (코드 수정 필요 시 해당 브랜치에서 수정 후 push)
6. CI 실패 → 원인 파악 후 수정
7. 모든 문제 해결 후 auto-merge 대기 또는 직접 머지

CONTEXT
    )

    # macOS에 timeout 없으므로 백그라운드 + wait로 대체
    /usr/local/bin/claude -p "$pr_context" \
        --max-turns 999 \
        --allowedTools "Bash,Read,Write,Edit,Glob,Grep" \
        2>&1 | tee "$log_file" &
    local claude_pid=$!
    ( sleep "$SESSION_TIMEOUT" && kill "$claude_pid" 2>/dev/null && echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⏰ Session timed out for PR #${pr_num}" ) &
    local timer_pid=$!
    wait "$claude_pid" 2>/dev/null
    kill "$timer_pid" 2>/dev/null
    wait "$timer_pid" 2>/dev/null
}

# ============================================================
# 메인 루프
# ============================================================
echo "[$(date '+%Y-%m-%d %H:%M:%S')] PR care worker started (poll: ${POLL_INTERVAL}s, stale: ${STALE_THRESHOLD}s)"

while true; do
    stale_prs=$(find_stale_pr)

    if [ -n "$stale_prs" ]; then
        count=$(echo "$stale_prs" | wc -l | tr -d ' ')
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Found $count stale PR(s)."
        for pr_num in $stale_prs; do
            care_pr "$pr_num"
        done
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] All stale PRs processed. Next cycle in ${POLL_INTERVAL}s..."
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] No stale PRs. Sleeping..."
    fi

    sleep "$POLL_INTERVAL"
done
