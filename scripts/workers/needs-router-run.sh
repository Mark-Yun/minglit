#!/bin/bash
# needs-router-run.sh — needs-* 라벨 감지 → 해당 워커 실행
# launchd가 30분마다 호출. 라벨 없으면 즉시 종료 (토큰 절약).
# 라벨→핸들러 매핑은 worker-routing.json의 routing 섹션을 따른다.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="Mark-Yun/minglit"
ROUTING_JSON="$SCRIPT_DIR/worker-routing.json"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] needs-router scanning..."

# worker-routing.json에서 needs-* 라벨 목록과 핸들러를 읽어온다
if [ ! -f "$ROUTING_JSON" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ Routing table not found: $ROUTING_JSON"
    exit 1
fi

found=0

# routing 섹션의 키(라벨)와 handler를 순회 (탭 구분자로 읽어 공백 포함 라벨 안전 처리)
while IFS=$'\t' read -r label handler; do
    if [ -z "${handler:-}" ] || [ "$handler" = "null" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ Invalid handler for label: $label"
        continue
    fi
    if [[ ! "$handler" =~ ^[a-z0-9-]+$ ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ Unsafe handler name for label $label: $handler"
        continue
    fi

    count=$(gh issue list --repo "$REPO" --label "$label" --state open --json number -q 'length' 2>/dev/null || echo "0")

    if [ "$count" -gt 0 ]; then
        script="$SCRIPT_DIR/${handler}-run.sh"

        if [ -x "$script" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Found $count issue(s) with $label → running ${handler}..."
            bash "$script" &
            found=$((found + 1))
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ Script not found: $script"
        fi
    fi
done < <(jq -r '.routing | to_entries[] | "\(.key)\t\(.value.handler // "null")"' "$ROUTING_JSON")

if [ "$found" -gt 0 ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Launched $found worker(s). Waiting..."
    wait
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] All workers done."
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] No needs-* labels found."
fi
