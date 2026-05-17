#!/usr/bin/env bash
set -euo pipefail
cd apps/app_user

# CUJ tests — emulator 기반 행위 검증.
# 대응 BLUEDOC: apps/app_user/integration_test/cuj/BLUEDOC.md
CUJ_DIR="integration_test/cuj"

if [ ! -d "$CUJ_DIR" ]; then
  echo "⏭ $CUJ_DIR not found, skipping."
  exit 0
fi

found=0
while IFS= read -r f; do
  [ -f "$f" ] || continue
  found=1
  echo "▶ Running: $f"
  flutter test "$f" \
    --flavor dev \
    --dart-define-from-file=../../minglit_env/dev/flutter.env
done < <(find "$CUJ_DIR" -name "*_test.dart" -not -path "*/_engine/*" | sort)

if [ "$found" -eq 0 ]; then
  echo "⏭ No CUJ tests found in $CUJ_DIR, skipping."
fi
