#!/usr/bin/env bash
# Verifies that every flutter key declared in env-manifest.json is also read
# via String.fromEnvironment in EnvKeyStore, and vice-versa.
#
# Run from the repo root: bash scripts/check-env-manifest-sync.sh
set -euo pipefail

MANIFEST="env-manifest.json"
KEYSTORE="shared/packages/minglit_kit/lib/src/config/env_keystore.dart"

# Extract flutter keys from env-manifest.json (required + optional sections)
MANIFEST_KEYS=$(jq -r '(.flutter.required // {}) + (.flutter.optional // {}) | keys[]' "$MANIFEST" | sort)

# Extract keys declared via String.fromEnvironment in env_keystore.dart.
# Handles both single-line and multi-line call sites.
KEYSTORE_KEYS=$(perl -0777 -ne 'while (/fromEnvironment\s*\(\s*'"'"'([A-Z_]+)/g) { print "$1\n" }' "$KEYSTORE" | sort -u)

MISSING_IN_KEYSTORE=$(comm -23 <(echo "$MANIFEST_KEYS") <(echo "$KEYSTORE_KEYS"))
EXTRA_IN_KEYSTORE=$(comm -13 <(echo "$MANIFEST_KEYS") <(echo "$KEYSTORE_KEYS"))

if [ -n "$MISSING_IN_KEYSTORE" ] || [ -n "$EXTRA_IN_KEYSTORE" ]; then
  echo "❌ Drift detected between $MANIFEST (flutter) and $KEYSTORE"
  if [ -n "$MISSING_IN_KEYSTORE" ]; then
    echo ""
    echo "Keys in env-manifest.json but missing from EnvKeyStore:"
    echo "$MISSING_IN_KEYSTORE" | sed 's/^/  - /'
  fi
  if [ -n "$EXTRA_IN_KEYSTORE" ]; then
    echo ""
    echo "Keys in EnvKeyStore but not in env-manifest.json (flutter):"
    echo "$EXTRA_IN_KEYSTORE" | sed 's/^/  - /'
  fi
  echo ""
  echo "Fix: update one of the two files to restore sync."
  exit 1
fi

echo "✅ env-manifest.json (flutter) and EnvKeyStore are in sync ($(echo "$MANIFEST_KEYS" | wc -l | tr -d ' ') keys)"
