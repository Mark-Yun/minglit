#!/bin/bash
# Load environment variables from minglit_env submodule.
# Usage: source scripts/load-env.sh [local|dev]

ENV=$1
if [ "$ENV" != "local" ] && [ "$ENV" != "dev" ]; then
  echo "Usage: source scripts/load-env.sh [local|dev]"
  return 1 2>/dev/null || exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_DIR="$ROOT_DIR/minglit_env/$ENV"

if [ ! -d "$ENV_DIR" ]; then
  echo "Error: $ENV_DIR not found. Run: git submodule update --init"
  return 1 2>/dev/null || exit 1
fi

for f in "$ENV_DIR"/*.env; do
  if [ -f "$f" ]; then
    export $(grep -v '^#' "$f" | grep -v '^$' | xargs)
  fi
done

echo "Loaded $ENV environment variables from minglit_env/$ENV/"
