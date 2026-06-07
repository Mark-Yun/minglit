#!/usr/bin/env bash
set -euo pipefail

: "${TARGET_SHA:?TARGET_SHA is required}"
: "${RENDER_SOURCE_DIR:?RENDER_SOURCE_DIR is required}"
: "${RELEASE_BOT_TOKEN:?RELEASE_BOT_TOKEN is required}"
: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${GITHUB_SERVER_URL:?GITHUB_SERVER_URL is required}"

ARCHIVE_BRANCH="${ARCHIVE_BRANCH:-artifacts/mds-render}"
SNAPSHOT_CHANNEL="${SNAPSHOT_CHANNEL:-dev}"
MAX_PUSH_ATTEMPTS="${MAX_PUSH_ATTEMPTS:-3}"
SNAPSHOT_PATH="snapshots/${SNAPSHOT_CHANNEL}/${TARGET_SHA}"
SHORT_SHA="${TARGET_SHA:0:8}"

if [[ ! "${TARGET_SHA}" =~ ^[0-9a-fA-F]{40}$ ]]; then
  echo "::error::TARGET_SHA must be a full 40-character commit SHA."
  exit 1
fi

if [ ! -d "${RENDER_SOURCE_DIR}" ]; then
  echo "::error::RENDER_SOURCE_DIR does not exist: ${RENDER_SOURCE_DIR}"
  exit 1
fi
RENDER_SOURCE_DIR="$(cd "${RENDER_SOURCE_DIR}" && pwd -P)"

PNG_COUNT="$(find "${RENDER_SOURCE_DIR}" -type f -name 'state-*.png' | wc -l | tr -d ' ')"
if [ "${PNG_COUNT}" = "0" ]; then
  echo "::error::No state PNG files found under ${RENDER_SOURCE_DIR}"
  exit 1
fi

REMOTE_URL="https://x-access-token:${RELEASE_BOT_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
SNAPSHOT_URL=""
ARCHIVE_COMMIT=""
BEFORE_COMMIT=""
CHANGED="false"
CHANGED_SCREENS=""
CHANGED_FILES=""

for attempt in $(seq 1 "${MAX_PUSH_ATTEMPTS}"); do
  WORK_DIR="$(mktemp -d)"
  trap 'rm -rf "${WORK_DIR}"' RETURN

  if git ls-remote --exit-code --heads "${REMOTE_URL}" "${ARCHIVE_BRANCH}" >/dev/null 2>&1; then
    git clone --depth=1 --branch "${ARCHIVE_BRANCH}" "${REMOTE_URL}" "${WORK_DIR}/archive"
    BEFORE_COMMIT="$(git -C "${WORK_DIR}/archive" rev-parse HEAD)"
  else
    mkdir -p "${WORK_DIR}/archive"
    git -C "${WORK_DIR}/archive" init
    git -C "${WORK_DIR}/archive" remote add origin "${REMOTE_URL}"
    git -C "${WORK_DIR}/archive" checkout --orphan "${ARCHIVE_BRANCH}"
    BEFORE_COMMIT="0000000000000000000000000000000000000000"
    {
      echo "# MDS Render Artifacts"
      echo ""
      echo "Git-backed visual evidence archive. Source branches do not merge this branch."
    } > "${WORK_DIR}/archive/README.md"
  fi

  cd "${WORK_DIR}/archive"
  git config user.name "minglit-release-bot"
  git config user.email "minglit-release-bot@users.noreply.github.com"

  rm -rf "${SNAPSHOT_PATH}"
  mkdir -p "${SNAPSHOT_PATH}"
  cp -a "${RENDER_SOURCE_DIR}/." "${SNAPSHOT_PATH}/"
  rm -f "${SNAPSHOT_PATH}/artifact-root.txt"

  {
    echo "# MDS Render Snapshot"
    echo ""
    echo "| Field | Value |"
    echo "|---|---|"
    echo "| channel | \`${SNAPSHOT_CHANNEL}\` |"
    echo "| source_sha | \`${TARGET_SHA}\` |"
    echo "| png_count | ${PNG_COUNT} |"
  } > "${SNAPSHOT_PATH}/_snapshot.md"

  git add README.md "${SNAPSHOT_PATH}"

  if git diff --cached --quiet; then
    ARCHIVE_COMMIT="$(git rev-parse HEAD)"
    SNAPSHOT_URL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/tree/${ARCHIVE_COMMIT}/${SNAPSHOT_PATH}"
    CHANGED="false"
    break
  fi

  CHANGED="true"
  CHANGED_FILES="$(git diff --cached --name-status -- "${SNAPSHOT_PATH}" | sed -n '1,200p')"
  CHANGED_SCREENS="$(
    git diff --cached --name-only -- "${SNAPSHOT_PATH}" \
      | awk -F/ 'NF >= 5 && $5 ~ /^state-.*\.png$/ { print $4 }' \
      | sort -u \
      | paste -sd ',' -
  )"

  git commit -m "chore(mds-render): snapshot ${SNAPSHOT_CHANNEL} ${SHORT_SHA}"

  if git push origin "HEAD:refs/heads/${ARCHIVE_BRANCH}"; then
    ARCHIVE_COMMIT="$(git rev-parse HEAD)"
    SNAPSHOT_URL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/tree/${ARCHIVE_COMMIT}/${SNAPSHOT_PATH}"
    break
  fi

  if [ "${attempt}" = "${MAX_PUSH_ATTEMPTS}" ]; then
    echo "::error::Failed to push ${ARCHIVE_BRANCH} after ${MAX_PUSH_ATTEMPTS} attempts."
    exit 1
  fi

  echo "[mds-render] push rejected; retrying with fresh ${ARCHIVE_BRANCH} (${attempt}/${MAX_PUSH_ATTEMPTS})"
  cd - >/dev/null
  rm -rf "${WORK_DIR}"
  trap - RETURN
done

if [ -z "${SNAPSHOT_URL}" ] || [ -z "${ARCHIVE_COMMIT}" ]; then
  echo "::error::Archive snapshot URL was not resolved."
  exit 1
fi

{
  echo "snapshot_path=${SNAPSHOT_PATH}"
  echo "snapshot_url=${SNAPSHOT_URL}"
  echo "archive_commit=${ARCHIVE_COMMIT}"
  echo "before_commit=${BEFORE_COMMIT}"
  echo "png_count=${PNG_COUNT}"
  echo "changed=${CHANGED}"
  echo "changed_screens=${CHANGED_SCREENS}"
  echo "changed_files<<EOF"
  printf '%s\n' "${CHANGED_FILES}"
  echo "EOF"
} >> "${GITHUB_OUTPUT}"

{
  echo "## MDS render snapshot archive"
  echo ""
  echo "| Field | Value |"
  echo "|---|---|"
  echo "| source_sha | \`${TARGET_SHA}\` |"
  echo "| archive_branch | \`${ARCHIVE_BRANCH}\` |"
  echo "| before_commit | \`${BEFORE_COMMIT}\` |"
  echo "| archive_commit | \`${ARCHIVE_COMMIT}\` |"
  echo "| snapshot_path | \`${SNAPSHOT_PATH}\` |"
  echo "| png_count | ${PNG_COUNT} |"
  echo "| changed | ${CHANGED} |"
  echo "| snapshot_url | ${SNAPSHOT_URL} |"
  if [ -n "${CHANGED_SCREENS}" ]; then
    echo "| changed_screens | ${CHANGED_SCREENS} |"
  fi
} >> "${GITHUB_STEP_SUMMARY}"
