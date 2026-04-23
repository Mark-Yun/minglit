#!/usr/bin/env bash
set -euo pipefail
cd apps/app_partner
# Fix #1557: CUJ tests live in test/integration/, not integration_test/
found=0
for f in test/integration/*_test.dart; do
  [ -f "$f" ] || break
  found=1
  echo "▶ Running: $f"
  flutter test "$f" --flavor dev --dart-define-from-file=../../minglit_env/dev/flutter.env
done
# Fix #1755: [ ... ] && echo 패턴은 found=1 일 때 마지막 명령이 exit 1 → 스크립트 종료 코드 1
if [ "$found" -eq 0 ]; then echo "⏭ No integration tests found, skipping."; fi
