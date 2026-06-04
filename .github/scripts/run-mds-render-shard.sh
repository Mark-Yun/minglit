#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${APP_NAME:?APP_NAME is required}"
SHARD_INDEX="${SHARD_INDEX:?SHARD_INDEX is required}"
SHARD_TOTAL="${SHARD_TOTAL:?SHARD_TOTAL is required}"
OUTPUT_ROOT="docs/infra/mds-emulator-render"
APP_DIR="apps/app_${APP_NAME}"
DRY_RUN="${MDS_RENDER_DRY_RUN:-0}"

if [ "$DRY_RUN" != "1" ]; then
  rm -rf "$OUTPUT_ROOT"
  mkdir -p "$OUTPUT_ROOT"
  touch "$OUTPUT_ROOT/artifact-root.txt"
fi

cd "$APP_DIR"

mapfile -t SCREENS < <(
  find integration_test/mds-emulator-render -mindepth 1 -maxdepth 1 -type d -printf '%f\n' \
    | grep -v '^_' \
    | sort
)

if [ "${#SCREENS[@]}" -eq 0 ]; then
  echo "::error::No catalog screen directories found for $APP_NAME"
  exit 1
fi

RUN_COUNT=0
for i in "${!SCREENS[@]}"; do
  if (( i % SHARD_TOTAL != SHARD_INDEX )); then
    continue
  fi

  SCREEN="${SCREENS[$i]}"
  TARGET="integration_test/mds-emulator-render/${SCREEN}/${SCREEN}_test.dart"
  SCREEN_OUTPUT="../../${OUTPUT_ROOT}/${SCREEN}"

  if [ ! -f "$TARGET" ]; then
    echo "::error::Missing render target: $TARGET"
    exit 1
  fi

  echo "[mds-render] app=$APP_NAME shard=${SHARD_INDEX}/${SHARD_TOTAL} target=$TARGET"
  if [ "$DRY_RUN" = "1" ]; then
    RUN_COUNT=$((RUN_COUNT + 1))
    continue
  fi

  rm -rf "$SCREEN_OUTPUT"

  flutter drive \
    --driver=test_driver/mds_emulator_render_driver.dart \
    --target="$TARGET" \
    --flavor dev \
    --dart-define-from-file=../../minglit_env/dev/flutter.env \
    -d emulator-5554

  PNG_COUNT=$(find "$SCREEN_OUTPUT" -maxdepth 1 -type f -name 'state-*.png' | wc -l | tr -d ' ')
  echo "[mds-render] captured ${PNG_COUNT} PNG(s) for $SCREEN"
  if [ "$PNG_COUNT" = "0" ]; then
    echo "::error::No state PNG captured for screen '$SCREEN'"
    exit 1
  fi

  RUN_COUNT=$((RUN_COUNT + 1))
done

if [ "$RUN_COUNT" = "0" ]; then
  echo "::error::Shard ${SHARD_INDEX}/${SHARD_TOTAL} had no assigned targets"
  exit 1
fi

if [ "$DRY_RUN" = "1" ]; then
  echo "[mds-render] dry-run complete: app=$APP_NAME shard=$SHARD_INDEX targets=$RUN_COUNT"
  exit 0
fi

TOTAL_PNG=$(find "../../${OUTPUT_ROOT}" -type f -name 'state-*.png' | wc -l | tr -d ' ')
echo "[mds-render] shard complete: app=$APP_NAME shard=$SHARD_INDEX targets=$RUN_COUNT pngs=$TOTAL_PNG"
