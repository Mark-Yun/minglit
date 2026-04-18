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
[ "$found" -eq 0 ] && echo "⏭ No integration tests found, skipping."
