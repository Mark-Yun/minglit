#!/usr/bin/env bash
set -euo pipefail
cd apps/app_partner

# CUJ tests — emulator 기반 행위 검증.
# 대응 BLUEDOC: apps/app_partner/integration_test/cuj/BLUEDOC.md
CUJ_DIR="integration_test/cuj"
DART_DEFINE_FILE="${MINGLIT_CUJ_DART_DEFINE_FILE:-../../minglit_env/dev/flutter.env}"

if [ ! -d "$CUJ_DIR" ]; then
  echo "⏭ $CUJ_DIR not found, skipping."
  exit 0
fi

found=0
failed=0
failures=()
while IFS= read -r f; do
  [ -f "$f" ] || continue
  found=1
  echo "▶ Running: $f"
  if ! flutter test "$f" \
    --flavor dev \
    --dart-define-from-file="$DART_DEFINE_FILE"; then
    failed=1
    failures+=("$f")
    echo "❌ Failed: $f"
  fi
done < <(find "$CUJ_DIR" -name "*_test.dart" -not -path "*/_engine/*" | sort)

if [ "$found" -eq 0 ]; then
  echo "⏭ No CUJ tests found in $CUJ_DIR, skipping."
fi

if [ "$failed" -ne 0 ]; then
  echo "❌ CUJ failures:"
  printf ' - %s\n' "${failures[@]}"
  exit 1
fi
