#!/usr/bin/env bash
# check-cross-feature-imports.sh
# Detects cross-feature imports inside apps/app_user and apps/app_partner.
# Violations that exist in .cross-feature-import-baseline are allowed (grandfathered).
# Any NEW violation causes a non-zero exit.
#
# Detects two forms of cross-feature import (feature X importing from Y, X != Y):
#   1. package imports:  import 'package:<app>/src/features/<Y>/...'
#   2. relative imports: import '../<Y>/...' (resolved via Python path normalisation)
#
# Fix #1872: enforce no new cross-feature imports; existing violations are
# tracked in .cross-feature-import-baseline pending removal (#1872 follow-ups).

set -euo pipefail

BASELINE_FILE="${BASELINE_FILE:-.cross-feature-import-baseline}"
FAIL=0
NEW_VIOLATIONS=()

check_app() {
  local app="$1"          # e.g. apps/app_user
  local pkg="$2"          # e.g. app_user
  local features_dir="${app}/lib/src/features"

  [[ -d "$features_dir" ]] || return 0

  while IFS= read -r -d '' dart_file; do
    # Derive source feature from path
    rel="${dart_file#${features_dir}/}"
    src_feature="${rel%%/*}"

    # Scan each import line for a cross-feature reference
    while IFS= read -r line; do
      # 1. package: imports
      if [[ "$line" =~ import\ \'package:${pkg}/src/features/([^/\']+)/ ]]; then
        tgt_feature="${BASH_REMATCH[1]}"
        if [[ "$tgt_feature" != "$src_feature" ]]; then
          entry="${rel}: ${src_feature} -> ${tgt_feature}"
          if ! grep -qxF "$entry" "$BASELINE_FILE" 2>/dev/null; then
            NEW_VIOLATIONS+=("$app/$entry")
            FAIL=1
          fi
        fi
      fi

      # 2. relative imports starting with ../
      if [[ "$line" =~ import\ \'(\.\.[^\']*)\'  ]]; then
        rel_import="${BASH_REMATCH[1]}"
        file_dir="$(dirname "$dart_file")"
        # Normalise the relative path using Python (available on all CI runners)
        import_resolved="$(python3 -c "import os,sys; print(os.path.normpath(os.path.join(sys.argv[1], sys.argv[2])))" "$file_dir" "$rel_import" 2>/dev/null || true)"
        # Check whether the resolved path falls inside a different feature
        if [[ "$import_resolved" == "${features_dir}/"* ]]; then
          import_inner="${import_resolved#${features_dir}/}"
          tgt_feature_rel="${import_inner%%/*}"
          if [[ -n "$tgt_feature_rel" && "$tgt_feature_rel" != "$src_feature" ]]; then
            entry="${rel}: ${src_feature} -> ${tgt_feature_rel}"
            if ! grep -qxF "$entry" "$BASELINE_FILE" 2>/dev/null; then
              NEW_VIOLATIONS+=("$app/$entry")
              FAIL=1
            fi
          fi
        fi
      fi
    done < "$dart_file"
  done < <(find "$features_dir" -name "*.dart" -print0)
}

check_app "apps/app_user"    "app_user"
check_app "apps/app_partner" "app_partner"

if [[ "$FAIL" -eq 0 ]]; then
  echo "✅ No new cross-feature imports detected."
  exit 0
fi

echo "❌ New cross-feature imports found (not in baseline):"
for v in "${NEW_VIOLATIONS[@]}"; do
  echo "  $v"
done
echo ""
echo "To grandfather an existing violation, add it to $BASELINE_FILE."
echo "To fix it properly, route through a shared module or coordinator."
exit 1
