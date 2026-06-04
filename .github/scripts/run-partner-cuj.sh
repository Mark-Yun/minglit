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

cuj_files=()
while IFS= read -r f; do
  [ -f "$f" ] || continue
  cuj_files+=("$f")
done < <(find "$CUJ_DIR" -name "*_test.dart" -not -path "*/_engine/*" | sort)

if [ "${#cuj_files[@]}" -eq 0 ]; then
  echo "⏭ No CUJ tests found in $CUJ_DIR, skipping."
  exit 0
fi

echo "▶ Running ${#cuj_files[@]} CUJ files in one Flutter test invocation:"
printf ' - %s\n' "${cuj_files[@]}"

flutter test "${cuj_files[@]}" \
  --flavor dev \
  --dart-define-from-file="$DART_DEFINE_FILE" \
  --no-pub
