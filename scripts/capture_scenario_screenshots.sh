#!/usr/bin/env bash
# capture_scenario_screenshots.sh — 에뮬레이터/실물 디바이스에서 시나리오 스크린샷 캡처
#
# 사용법:
#   ./scripts/capture_scenario_screenshots.sh [app_user|app_partner|all] [device_id]
#
# 예시:
#   ./scripts/capture_scenario_screenshots.sh app_user emulator-5554
#   ./scripts/capture_scenario_screenshots.sh all R3CX803P2ND

set -e

APP="${1:-all}"
DEVICE="${2:-}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

run_screenshots() {
  local app="$1"
  local device_flag=""
  if [ -n "$DEVICE" ]; then
    device_flag="-d $DEVICE"
  fi

  echo "=== $app 스크린샷 캡처 시작 ==="
  cd "$REPO_ROOT/apps/$app"
  flutter test integration_test/scenario_screenshots_test.dart \
    --flavor dev \
    $device_flag \
    --reporter expanded
  cd "$REPO_ROOT"
  echo "=== $app 스크린샷 캡처 완료 ==="
}

case "$APP" in
  app_user)
    run_screenshots "app_user"
    ;;
  app_partner)
    run_screenshots "app_partner"
    ;;
  all)
    run_screenshots "app_user"
    run_screenshots "app_partner"
    ;;
  *)
    echo "사용법: $0 [app_user|app_partner|all] [device_id]"
    exit 1
    ;;
esac

echo "완료. 스크린샷은 --screenshot-path 옵션으로 저장 경로 지정 가능."
