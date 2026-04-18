#!/usr/bin/env bash
set -euo pipefail
cd apps/app_user
# Fix #1557: CUJ tests live in test/integration/, not integration_test/
for f in test/integration/*_test.dart; do
  [ -f "$f" ] || { echo "⏭ No integration tests found, skipping."; break; }
  echo "▶ Running: $f"
  flutter test "$f" --flavor dev --dart-define-from-file=../../minglit_env/dev/flutter.env
done
