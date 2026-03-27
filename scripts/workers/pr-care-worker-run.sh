#!/bin/bash
# pr-care-run.sh — 단발성. stale PR 케어.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="/Users/mark/workspace/minglit"
SESSION_TIMEOUT=3600
STALE_THRESHOLD=1800
REPO="Mark-Yun/minglit"
LOG_DIR="/tmp/claude-pr-care-logs"

mkdir -p "$LOG_DIR"

stale_prs=$(python3 -c "
import subprocess, json, sys
from datetime import datetime, timezone
now = datetime.now(timezone.utc)
result = subprocess.run(['gh','pr','list','--repo','$REPO','--state','open',
    '--json','number,updatedAt,mergeStateStatus,author,autoMergeRequest'],
    capture_output=True, text=True)
prs = json.loads(result.stdout)
stale = []
for pr in prs:
    updated = datetime.fromisoformat(pr['updatedAt'].replace('Z','+00:00'))
    if (now - updated).total_seconds() >= $STALE_THRESHOLD:
        stale.append({
            'number': pr['number'],
            'status': pr['mergeStateStatus'],
            'author': pr['author']['login'],
        })
stale.sort(key=lambda x: (-{'BEHIND':2,'BLOCKED':1}.get(x['status'],0)))
for s in stale:
    print(s['number'])
" 2>/dev/null)

[ -z "$stale_prs" ] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] No stale PRs." && exit 0

for pr_num in $stale_prs; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Caring for PR #${pr_num}..."
    log_file="$LOG_DIR/pr-${pr_num}-$(date +%Y%m%d-%H%M%S).log"

    status=$(gh pr view "$pr_num" --repo "$REPO" --json mergeStateStatus -q '.mergeStateStatus')
    if [ "$status" = "BEHIND" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] PR #${pr_num} BEHIND — updating..."
        gh api "repos/${REPO}/pulls/${pr_num}/update-branch" --method PUT 2>&1 | tee "$log_file"
        continue
    fi

    author=$(gh pr view "$pr_num" --repo "$REPO" --json author -q '.author.login')
    if [[ "$author" == "dependabot[bot]" ]]; then
        fail_count=$(gh pr checks "$pr_num" --repo "$REPO" 2>&1 | grep -v "pass\|skipped" | grep -c "fail" || echo "0")
        if [ "$fail_count" = "0" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Dependabot PR #${pr_num} — merging..."
            gh pr merge "$pr_num" --repo "$REPO" --squash 2>&1 | tee "$log_file"
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Dependabot PR #${pr_num} — CI failed, closing..."
            gh pr close "$pr_num" --repo "$REPO" --comment "🤖 PR Care: CI 실패로 자동 close." 2>&1 | tee -a "$log_file"
        fi
        continue
    fi

    # PR 브랜치용 worktree 생성
    WORKTREE_BASE="/Users/mark/workspace/minglit-workers"
    head_branch=$(gh pr view "$pr_num" --repo "$REPO" --json headRefName -q '.headRefName')
    worktree_dir="$WORKTREE_BASE/pr-${pr_num}"
    if [ ! -d "$worktree_dir" ]; then
        mkdir -p "$WORKTREE_BASE"
        if ! git -C "$REPO_DIR" fetch origin "$head_branch" 2>&1; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: fetch failed for $head_branch"
        fi
        if ! git -C "$REPO_DIR" worktree add "$worktree_dir" "origin/$head_branch" 2>&1; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARN: worktree add failed for pr-${pr_num}, falling back to REPO_DIR"
        fi
    else
        cd "$worktree_dir" && git fetch origin "$head_branch" && git reset --hard "origin/$head_branch" 2>/dev/null
    fi
    cd "$worktree_dir" 2>/dev/null || cd "$REPO_DIR" || exit 1
    pr_context="PR #${pr_num} 케어. 상태: ${status}, 작성자: ${author}, 브랜치: ${head_branch}. gh pr checks ${pr_num}로 CI 확인, 리뷰 코멘트 대응, BEHIND면 업데이트, CI 실패면 수정 후 push."
    /usr/local/bin/claude -p "$pr_context" \
        --max-turns 999 \
        --allowedTools "Bash,Read,Write,Edit,Glob,Grep,Agent" \
        > >(tee "$log_file") 2>&1 &
    claude_pid=$!
    ( sleep "$SESSION_TIMEOUT" && kill "$claude_pid" 2>/dev/null ) &
    timer_pid=$!
    wait "$claude_pid" 2>/dev/null
    kill "$timer_pid" 2>/dev/null; wait "$timer_pid" 2>/dev/null
done
