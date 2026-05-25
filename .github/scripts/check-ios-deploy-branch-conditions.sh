#!/usr/bin/env bash
set -euo pipefail

ACTION_FILE=".github/actions/ios-deploy/action.yml"

if [[ ! -f "$ACTION_FILE" ]]; then
  echo "ERROR: Missing $ACTION_FILE"
  exit 1
fi

# Regression guard: dev-staging (and any non-main branch) must go through
# development build/signing path, not be silently skipped.
if rg -n "refs/heads/dev" "$ACTION_FILE" >/dev/null; then
  echo "ERROR: Found legacy refs/heads/dev checks in $ACTION_FILE"
  rg -n "refs/heads/dev" "$ACTION_FILE"
  exit 1
fi

required_patterns=(
  "inputs.git-ref != 'refs/heads/main'"
  '[ "$GIT_REF" != "refs/heads/main" ]'
)

for pattern in "${required_patterns[@]}"; do
  if ! rg -F "$pattern" "$ACTION_FILE" >/dev/null; then
    echo "ERROR: Missing required branch condition pattern: $pattern"
    exit 1
  fi
done

echo "OK: iOS deploy branch conditions validated (main vs non-main)"
