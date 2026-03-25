#!/usr/bin/env bash
# audit-uiux-worker.sh — UI/UX 디자인 시스템 감사 워커
# 24시간 주기로 하드코딩 색상/폰트, golden test 미존재, 디자인 토큰 위반을 감사하고
# 위반 발견 시 GitHub Issue를 생성한다.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORKTREE_DIR="${REPO_ROOT}/../minglit-workers/audit-uiux"
INTERVAL=86400  # 24시간
SESSION_NAME="audit-uiux"
PROMPT_FILE="${REPO_ROOT}/scripts/workers/prompts/audit-uiux.txt"

# ── worktree 준비 ──────────────────────────────────────────────
setup_worktree() {
  if [ ! -d "$WORKTREE_DIR" ]; then
    echo "[audit-uiux] Creating worktree at $WORKTREE_DIR (detached HEAD) ..."
    git -C "$REPO_ROOT" worktree add --detach "$WORKTREE_DIR"
  else
    echo "[audit-uiux] Worktree already exists. Updating ..."
    git -C "$WORKTREE_DIR" fetch origin dev --quiet
    git -C "$WORKTREE_DIR" checkout --detach origin/dev --quiet
  fi
}

# ── 메인 루프 ──────────────────────────────────────────────────
run_loop() {
  while true; do
    LOGFILE="/tmp/audit-uiux-$(date +%Y%m%d-%H%M%S).log"
    echo "[audit-uiux] $(date '+%Y-%m-%d %H:%M:%S') — 감사 시작 (log: $LOGFILE)"

    setup_worktree

    claude \
      --print \
      --max-turns 30 \
      --allowedTools "Bash,Read,Write,Edit,Glob,Grep" \
      --prompt-file "$PROMPT_FILE" \
      --directory "$WORKTREE_DIR" \
      > "$LOGFILE" 2>&1 || true

    echo "[audit-uiux] $(date '+%Y-%m-%d %H:%M:%S') — 감사 완료. 다음 실행까지 ${INTERVAL}초 대기."
    sleep "$INTERVAL"
  done
}

# ── tmux 세션으로 실행 ─────────────────────────────────────────
if [ "${1:-}" = "--foreground" ]; then
  run_loop
else
  if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "[audit-uiux] tmux 세션 '$SESSION_NAME'이 이미 실행 중입니다."
    exit 0
  fi
  tmux new-session -d -s "$SESSION_NAME" "$0 --foreground"
  echo "[audit-uiux] tmux 세션 '$SESSION_NAME' 시작됨. 접속: tmux attach -t $SESSION_NAME"
fi
