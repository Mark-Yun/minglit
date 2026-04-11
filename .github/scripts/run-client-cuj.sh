#!/usr/bin/env bash
set -euo pipefail
cd apps/app_user
for f in integration_test/*_test.dart; do
  [ -f "$f" ] || { echo "⏭ No integration tests found, skipping."; break; }
  echo "▶ Running: $f"
  flutter test "$f" --flavor dev --dart-define-from-file=../../minglit_env/dev/flutter.env
done
