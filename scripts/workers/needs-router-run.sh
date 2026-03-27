#!/bin/bash
# needs-router-run.sh — needs-* 라벨 감지 → 해당 audit 워커 실행
# launchd가 30분마다 호출. 라벨 없으면 즉시 종료 (토큰 절약).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="Mark-Yun/minglit"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] needs-router scanning..."

found=0

for label in needs-arch needs-uiux needs-qa needs-security needs-legal; do
    count=$(gh issue list --repo "$REPO" --label "$label" --state open --json number -q 'length' 2>/dev/null || echo "0")

    if [ "$count" -gt 0 ]; then
        worker="${label#needs-}"  # needs-uiux → uiux
        script="$SCRIPT_DIR/audit-${worker}-run.sh"

        if [ -x "$script" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Found $count issue(s) with $label → running audit-${worker}..."
            bash "$script" &
            found=$((found + 1))
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ Script not found: $script"
        fi
    fi
done

if [ "$found" -gt 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Launched $found worker(s). Waiting..."
    wait
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] All workers done."
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] No needs-* labels found."
fi
