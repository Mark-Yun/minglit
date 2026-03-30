#!/usr/bin/env bash
# pre-commit.sh — Run targeted tests based on changed files
# Usage: bash scripts/pre-commit.sh [--help]
#
# Install as git hook:
#   cp scripts/pre-commit.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit

set -euo pipefail

if [[ "${1:-}" == "--help" ]]; then
  echo "pre-commit.sh: Run targeted tests based on changed files"
  echo ""
  echo "Detects changes in:"
  echo "  supabase/migrations/*.sql  → supabase test db"
  echo "  supabase/functions/**/*.ts → deno test (changed function)"
  echo "  tests/backend_integration/**/*.dart → dart test (changed file)"
  echo ""
  echo "Usage: bash scripts/pre-commit.sh [--help]"
  exit 0
fi

CHANGED_FILES=$(git diff --cached --name-only 2>/dev/null || git diff --name-only HEAD 2>/dev/null || echo "")

if [[ -z "$CHANGED_FILES" ]]; then
  echo "✅ No staged changes detected."
  exit 0
fi

RAN_ANY=false

# 1. supabase/migrations 변경 → supabase test db
if echo "$CHANGED_FILES" | grep -q "^supabase/migrations/"; then
  echo "🔍 Migration changes detected → running supabase test db"
  if command -v supabase &>/dev/null; then
    supabase test db
    RAN_ANY=true
  else
    echo "⚠️  supabase CLI not found. Skipping pgTAP tests."
  fi
fi

# 2. supabase/functions 변경 → deno test (해당 함수만)
CHANGED_FUNCTIONS=$(echo "$CHANGED_FILES" | grep "^supabase/functions/" | sed 's|supabase/functions/\([^/]*\)/.*|\1|' | sort -u | grep -v "^_" || true)
if [[ -n "$CHANGED_FUNCTIONS" ]]; then
  echo "🔍 Edge Function changes detected → running deno test"
  if command -v deno &>/dev/null; then
    while IFS= read -r fn; do
      if [[ -d "supabase/functions/$fn" ]]; then
        echo "  → deno test supabase/functions/$fn/"
        deno test --allow-all "supabase/functions/$fn/"
        RAN_ANY=true
      fi
    done <<< "$CHANGED_FUNCTIONS"
  else
    echo "⚠️  deno not found. Skipping Edge Function tests."
  fi
fi

# 3. tests/backend_integration 변경 → dart test (해당 파일만)
CHANGED_DART=$(echo "$CHANGED_FILES" | grep "^tests/backend_integration/.*_test\.dart$" || true)
if [[ -n "$CHANGED_DART" ]]; then
  echo "🔍 Dart integration test changes detected → running dart test"
  if command -v dart &>/dev/null; then
    while IFS= read -r f; do
      echo "  → dart test $f"
      dart test "$f"
      RAN_ANY=true
    done <<< "$CHANGED_DART"
  else
    echo "⚠️  dart not found. Skipping integration tests."
  fi
fi

if [[ "$RAN_ANY" == "false" ]]; then
  echo "✅ No test-relevant changes detected. Skipping tests."
fi

echo "✅ pre-commit checks complete."
