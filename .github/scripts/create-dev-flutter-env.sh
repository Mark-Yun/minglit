#!/usr/bin/env bash
set -euo pipefail

: "${SUPABASE_URL:?SUPABASE_URL is required}"
: "${SUPABASE_PUBLISHABLE_KEY:?SUPABASE_PUBLISHABLE_KEY is required}"

env_file="minglit_env/dev/flutter.env"

# Fix #1169: CI checkout does not include the private minglit_env submodule, so
# rebuild the dev Flutter env file from Actions secrets before CUJ tests.
umask 077
mkdir -p "$(dirname "$env_file")"
cat >"$env_file" <<EOF
SUPABASE_URL=$SUPABASE_URL
SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY
ENVIRONMENT=${ENVIRONMENT:-development}
SENTRY_DSN=${SENTRY_DSN:-}
STATSIG_CLIENT_KEY=${STATSIG_CLIENT_KEY:-}
GOOGLE_WEB_CLIENT_ID=${GOOGLE_WEB_CLIENT_ID:-}
KAKAO_LOCAL_REST_API_KEY=${KAKAO_LOCAL_REST_API_KEY:-}
KAKAO_MAP_JAVASCRIPT_KEY=${KAKAO_MAP_JAVASCRIPT_KEY:-}
JUSO_CONFIRM_KEY=${JUSO_CONFIRM_KEY:-}
IAMPORT_USER_CODE=${IAMPORT_USER_CODE:-}
MOBILE_REDIRECT_SCHEME=${MOBILE_REDIRECT_SCHEME:-}
EOF

echo "Created $env_file"
