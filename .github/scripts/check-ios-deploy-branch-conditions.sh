#!/usr/bin/env bash
set -euo pipefail

ACTION_FILE=".github/actions/ios-deploy/action.yml"
WORKFLOW_FILE=".github/workflows/shared-ios-deploy.yml"
APP_PUBSPECS=(
  "apps/app_user/pubspec.yaml"
  "apps/app_partner/pubspec.yaml"
)

require_file() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "ERROR: Missing $file"
    exit 1
  fi
}

require_file "$ACTION_FILE"
require_file "$WORKFLOW_FILE"
for pubspec in "${APP_PUBSPECS[@]}"; do
  require_file "$pubspec"
done

count_matches() {
  local pattern="$1"
  local file="$2"
  (grep -nE "$pattern" "$file" || true) | wc -l | tr -d ' '
}

assert_flutter_spm_disabled() {
  local pubspec="$1"
  if ! awk '
    /^flutter:[[:space:]]*$/ {
      in_flutter = 1
      in_config = 0
      next
    }
    in_flutter && /^[^[:space:]#][^:]*:/ {
      in_flutter = 0
      in_config = 0
    }
    in_flutter && /^[[:space:]]{2}config:[[:space:]]*$/ {
      in_config = 1
      next
    }
    in_config && /^[[:space:]]{2}[^[:space:]#][^:]*:/ {
      in_config = 0
    }
    in_config && /^[[:space:]]{4}enable-swift-package-manager:[[:space:]]*false([[:space:]]*(#.*)?)?$/ {
      found = 1
    }
    END {
      exit found ? 0 : 1
    }
  ' "$pubspec"; then
    echo "ERROR: $pubspec must set flutter.config.enable-swift-package-manager: false for CocoaPods-based iOS deploy"
    exit 1
  fi
}

# Regression guard: dev-staging (and any non-main branch) must go through
# development build/signing path, not be silently skipped.
if grep -nE "refs/heads/dev" "$ACTION_FILE" >/dev/null; then
  echo "ERROR: Found legacy refs/heads/dev checks in $ACTION_FILE"
  grep -nE "refs/heads/dev" "$ACTION_FILE"
  exit 1
fi

required_patterns=(
  "inputs.git-ref != 'refs/heads/main'"
  '[ "$GIT_REF" != "refs/heads/main" ]'
)

for pattern in "${required_patterns[@]}"; do
  if ! grep -nF "$pattern" "$ACTION_FILE" >/dev/null; then
    echo "ERROR: Missing required branch condition pattern: $pattern"
    exit 1
  fi
done

timeout_minutes="$( (grep -nE "^[[:space:]]*timeout-minutes:[[:space:]]*[0-9]+" "$WORKFLOW_FILE" || true) \
  | head -n1 \
  | sed -E 's/.*timeout-minutes:[[:space:]]*([0-9]+).*/\1/')"

if ! grep -nE "^[[:space:]]*runs-on:[[:space:]]*macos-26([[:space:]]*(#.*)?)?$" "$WORKFLOW_FILE" >/dev/null; then
  echo "ERROR: shared-ios-deploy must run on macos-26 so App Store Connect uploads are built with iOS 26 SDK"
  grep -nE "^[[:space:]]*runs-on:" "$WORKFLOW_FILE" || true
  exit 1
fi

if [[ -z "$timeout_minutes" ]]; then
  echo "ERROR: Could not detect timeout-minutes in $WORKFLOW_FILE"
  exit 1
fi

if (( timeout_minutes < 120 )); then
  echo "ERROR: shared-ios-deploy timeout-minutes must be >= 120 (found: $timeout_minutes)"
  exit 1
fi

heartbeat_wrapper_count="$(count_matches "run_with_heartbeat\\(\\)" "$ACTION_FILE")"
heartbeat_invocation_count="$(count_matches "run_with_heartbeat flutter build ipa --release" "$ACTION_FILE")"
wait_capture_count="$(count_matches 'if wait "\$build_pid"; then' "$ACTION_FILE")"
status_return_count="$(count_matches 'return "\$status"' "$ACTION_FILE")"
direct_build_invocation_count="$(count_matches "^[[:space:]]*flutter build ipa --release" "$ACTION_FILE")"

if (( heartbeat_wrapper_count < 2 )); then
  echo "ERROR: Expected heartbeat wrapper in both dev/main build steps (found: $heartbeat_wrapper_count)"
  exit 1
fi

if (( heartbeat_invocation_count < 2 )); then
  echo "ERROR: Expected run_with_heartbeat flutter build ipa in both dev/main build steps (found: $heartbeat_invocation_count)"
  exit 1
fi

if (( wait_capture_count < 2 )) || (( status_return_count < 2 )); then
  echo "ERROR: Heartbeat wrapper must preserve flutter build exit code via wait/return (wait: $wait_capture_count, return: $status_return_count)"
  exit 1
fi

if (( direct_build_invocation_count > 0 )); then
  echo "ERROR: Direct 'flutter build ipa --release' invocation detected; use run_with_heartbeat wrapper"
  grep -nE "^[[:space:]]*flutter build ipa --release" "$ACTION_FILE"
  exit 1
fi

for pubspec in "${APP_PUBSPECS[@]}"; do
  assert_flutter_spm_disabled "$pubspec"
done

echo "OK: iOS deploy workflow contract validated (branch, runner SDK, timeout, heartbeat, exit-code, SPM disabled)"
