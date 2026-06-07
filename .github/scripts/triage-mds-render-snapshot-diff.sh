#!/usr/bin/env bash
set -euo pipefail

: "${GH_TOKEN:?GH_TOKEN is required}"
: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"
: "${GITHUB_SERVER_URL:?GITHUB_SERVER_URL is required}"
: "${GITHUB_RUN_ID:?GITHUB_RUN_ID is required}"

BEFORE_SHA="${BEFORE_SHA:-}"
AFTER_SHA="${AFTER_SHA:-$(git rev-parse HEAD)}"
ARCHIVE_BRANCH="${ARCHIVE_BRANCH:-artifacts/mds-render}"
DRY_RUN="${DRY_RUN:-false}"
RUN_URL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
ZERO_SHA="0000000000000000000000000000000000000000"

if [ -n "${BEFORE_SHA}" ] && [ "${BEFORE_SHA}" != "${ZERO_SHA}" ] && git cat-file -e "${BEFORE_SHA}^{commit}" 2>/dev/null; then
  DIFF_CMD=(git diff --name-status "${BEFORE_SHA}" "${AFTER_SHA}" -- snapshots/dev)
  COMPARE_URL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/compare/${BEFORE_SHA}...${AFTER_SHA}"
else
  DIFF_CMD=(git diff-tree --no-commit-id --name-status -r "${AFTER_SHA}" -- snapshots/dev)
  COMPARE_URL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/tree/${AFTER_SHA}/snapshots/dev"
fi

DIFF_FILE="$(mktemp)"
"${DIFF_CMD[@]}" > "${DIFF_FILE}"

PNG_PATHS_FILE="$(mktemp)"
awk '
  {
    path=$NF
    if (path ~ /^snapshots\/dev\/[0-9a-fA-F]{40}\/.*\/state-.*\.png$/) {
      print path
    }
  }
' "${DIFF_FILE}" | sort -u > "${PNG_PATHS_FILE}"

if [ ! -s "${PNG_PATHS_FILE}" ]; then
  echo "No MDS state PNG diff detected under snapshots/dev/**."
  exit 0
fi

SOURCE_SHAS=()
while IFS= read -r source_sha; do
  SOURCE_SHAS+=("${source_sha}")
done < <(awk -F/ '{ print $3 }' "${PNG_PATHS_FILE}" | sort -u)

for SOURCE_SHA in "${SOURCE_SHAS[@]}"; do
  SHORT_SHA="${SOURCE_SHA:0:8}"
  SNAPSHOT_PATH="snapshots/dev/${SOURCE_SHA}"
  SNAPSHOT_URL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/tree/${AFTER_SHA}/${SNAPSHOT_PATH}"
  TITLE="[mds-render-snapshot-diff] dev ${SHORT_SHA} visual snapshot changed"

  FILES_FOR_SHA="$(awk -v sha="${SOURCE_SHA}" '$0 ~ "snapshots/dev/" sha "/" { print }' "${DIFF_FILE}" | sed -n '1,200p')"
  SCREENS_FOR_SHA="$(
    awk -F/ -v sha="${SOURCE_SHA}" '$0 ~ "snapshots/dev/" sha "/" && $NF ~ /^state-.*\.png$/ { print $4 }' "${PNG_PATHS_FILE}" \
      | sort -u \
      | paste -sd ',' - \
      | sed 's/,/, /g'
  )"
  COMPARISON_TARGETS_FILE="$(mktemp)"
  {
    echo "| Screen | Snapshot state | Diff | Snapshot PNG | MDS spec |"
    echo "|---|---|---|---|---|"
    awk -v sha="${SOURCE_SHA}" '$0 ~ "snapshots/dev/" sha "/" { print }' "${DIFF_FILE}" \
      | while IFS=$'\t' read -r status path_a path_b; do
        path="${path_b:-${path_a}}"
        if [[ ! "${path}" =~ ^snapshots/dev/${SOURCE_SHA}/.*/state-.*\.png$ ]]; then
          continue
        fi
        screen="$(printf '%s\n' "${path}" | awk -F/ '{ print $4 }')"
        state_file="$(basename "${path}")"
        snapshot_png_url="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/blob/${AFTER_SHA}/${path}"
        spec_dir_url="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/tree/${SOURCE_SHA}/apps/mds/docs/public/specs/${screen}"
        echo "| ${screen} | ${state_file} | ${status} | [snapshot PNG](${snapshot_png_url}) | [MDS spec dir](${spec_dir_url}) |"
      done
  } > "${COMPARISON_TARGETS_FILE}"

  BODY_FILE="$(mktemp)"
  {
    echo "## MDS render snapshot diff"
    echo ""
    echo "| Field | Value |"
    echo "|---|---|"
    echo "| Source dev SHA | \`${SOURCE_SHA}\` |"
    echo "| Artifact branch | \`${ARCHIVE_BRANCH}\` |"
    echo "| Snapshot path | \`${SNAPSHOT_PATH}\` |"
    echo "| MDS spec root | \`apps/mds/docs/public/specs/<screen>/state_*.png\` |"
    echo "| Snapshot URL | ${SNAPSHOT_URL} |"
    echo "| Compare | ${COMPARE_URL} |"
    echo "| Workflow run | ${RUN_URL} |"
    echo "| Changed screens | ${SCREENS_FOR_SHA:-unknown} |"
    echo ""
    echo "## Changed files"
    echo ""
    echo '```text'
    printf '%s\n' "${FILES_FOR_SHA}"
    echo '```'
    echo ""
    echo "## Comparison targets"
    echo ""
    cat "${COMPARISON_TARGETS_FILE}"
    echo ""
    echo "> MDS spec 의 state 파일명은 \`state_1.png\`, \`state_2.png\` 처럼 순번 기반일 수 있다. Snapshot 의 \`state-*.png\` 와 이름이 직접 일치하지 않으면 MDS spec directory 의 \`index.md\` 와 state 순서를 확인해 같은 상태를 매칭한다."
    echo "> MDS PNG 는 시각 참조이고, \`index.md\` 의 Layout / States / visual 섹션을 최종 contract 로 삼는다. PNG 와 텍스트가 충돌하면 그 사실을 코멘트에 명시하고 텍스트 contract 기준으로 판정한다."
    echo ""
    echo "## Agent Contract"
    echo ""
    echo "목표: 변경된 MDS emulator render snapshot 이 해당 dev SHA 의 의도된 화면 상태를 올바르게 반영하는지 확인한다. 이 이슈를 맡은 에이전트는 아래 절차를 직접 수행하고, 결과를 댓글과 finding issue/status 로 남긴다."
    echo ""
    echo "### 단계별 확인 절차"
    echo ""
    echo "1. Pairing: 변경된 각 \`state-*.png\` 를 \`apps/mds/docs/public/specs/<screen>/state_*.png\` 의 같은 screen/state 원본과 1:1 로 매칭한다."
    echo "2. First pass: 전체 화면을 축소해서 hero/header/tab/body/bottom CTA 의 큰 구조, 잘림, 겹침, 빈 상태를 확인한다."
    echo "3. Component pass: 변경 화면의 버튼, 탭, 카드, 리스트 row, form field, icon+text control 을 개별 확대해 확인한다."
    echo "4. Sibling alignment pass: 같은 row 에 있는 형제 컨트롤의 top/bottom/center line, 높이, padding, icon baseline, text baseline 을 비교한다. 예: \`좋아요\` 와 \`공유하기\` 버튼은 같은 높이와 수직 정렬이어야 한다."
    echo "5. State semantics pass: disabled/loading/error/empty/selected 상태가 MDS spec 의 의도와 같은지 확인한다."
    echo "6. Regression pass: 변경이 최근 dev-staging -> dev 승격 내용으로 설명되는지 확인한다. 설명되지 않는 visual diff 는 blocker 후보로 본다."
    echo ""
    echo "### 반드시 코멘트에 남길 것"
    echo ""
    echo "- 확인한 screen/state 목록"
    echo "- spec 대비 차이가 있던 항목과 의도된 변경인지 여부"
    echo "- 버튼/탭/CTA 같은 같은-row 컨트롤의 수직 정렬 확인 결과"
    echo "- blocker 가 아니라면 왜 허용 가능한지에 대한 근거"
    echo "- blocker 라면 아래 Finding handling 절차로 만든 fix issue 링크"
    echo ""
    echo "### Finding handling"
    echo ""
    echo "- 이 review issue 는 visual diff 검토 태스크다. 확정된 visual blocker 를 이 이슈 하나에 묶어서 처리하지 않는다."
    echo "- 확정된 blocker 는 finding 당 별도 GitHub issue 를 생성한다."
    echo "- finding issue 는 AI worker 가 바로 수정할 수 있게 screen/state, snapshot URL, MDS spec 경로, 기대 동작, 실제 문제, 수정 완료 조건을 포함한다."
    echo "- finding issue 라벨은 기본 \`needs-swe\`, \`P1-high\`, \`release-blocker\`, \`automated\` 를 사용한다. 설계 판단이 먼저 필요하면 \`needs-arch\` 를 추가한다."
    echo "- 확정 blocker 가 1개 이상이면 source dev SHA 에 \`dev-soak/app-ai-review=failure\` commit status 를 즉시 남겨 RC cut gate 를 막는다."
    echo "- status target URL 은 이 review issue 또는 대표 finding issue 로 둔다."
    echo ""
    echo "Status 기록 예:"
    echo ""
    echo '```bash'
    echo "gh workflow run set-dev-soak-status.yml \\"
    echo "  -f signal=app-ai-review \\"
    echo "  -f state=failure \\"
    echo "  -f sha=${SOURCE_SHA} \\"
    echo "  -f target_url=<review-or-finding-issue-url> \\"
    echo "  -f description=\"visual blocker found in MDS render snapshot\""
    echo '```'
    echo ""
    echo "- blocker 가 없다고 확인되면 \`dev-soak/app-ai-review=success\` 를 같은 source dev SHA 에 남기고 근거 댓글 후 이슈를 닫는다."
    echo ""
    echo "### 종료 조건"
    echo ""
    echo "- 모든 변경 screen/state 를 위 절차로 확인했고, 변경이 의도된 결과이면 \`dev-soak/app-ai-review=success\` 근거를 댓글로 남기고 이슈를 닫는다."
    echo "- blocker 를 발견했다면 finding 별 fix issue 를 만들고 \`dev-soak/app-ai-review=failure\` status 를 남긴 뒤, 이 review issue 에 생성한 issue 링크를 남긴다."
    echo "- fix issue 가 해결되면 다음 dev 승격에서 새 snapshot 으로 재검증한다."
    echo "- 인프라/렌더러 문제로 판단이 불가능하면 \`exec-report\` 라벨을 붙이고 필요한 사람 조치사항을 댓글로 남긴다."
    echo ""
    echo "### 하지 말 것"
    echo ""
    echo "- \`artifacts/mds-render\` 브랜치를 직접 수정하지 않는다."
    echo "- PNG snapshot 을 \`dev-staging\`, \`dev\`, \`rc/*\`, \`main\` 에 커밋하지 않는다."
    echo "- visual blocker 를 \`dev\` 에 직접 고치지 않는다. fix 는 항상 \`dev-staging\` 으로 들어간다."
    echo ""
    echo "<!-- minglit-mds-render-snapshot-diff"
    echo "source_sha: ${SOURCE_SHA}"
    echo "archive_branch: ${ARCHIVE_BRANCH}"
    echo "snapshot_path: ${SNAPSHOT_PATH}"
    echo "after_sha: ${AFTER_SHA}"
    echo "run_id: ${GITHUB_RUN_ID}"
    echo "-->"
  } > "${BODY_FILE}"

  if [ "${DRY_RUN}" = "true" ]; then
    echo "## Dry run issue body: ${TITLE}"
    cat "${BODY_FILE}"
    continue
  fi

  EXISTING="$(gh issue list \
    --repo "${GITHUB_REPOSITORY}" \
    --search "\"${TITLE}\" in:title state:open" \
    --json number \
    --jq '.[0].number // empty')"

  if [ -n "${EXISTING}" ]; then
    gh issue comment "${EXISTING}" --repo "${GITHUB_REPOSITORY}" --body-file "${BODY_FILE}"
    ISSUE_NUMBER="${EXISTING}"
    echo "Updated existing issue #${ISSUE_NUMBER}: ${TITLE}"
  else
    ISSUE_URL="$(gh issue create \
      --repo "${GITHUB_REPOSITORY}" \
      --title "${TITLE}" \
      --body-file "${BODY_FILE}" \
      --label needs-arch \
      --label automated \
      --label P1-high)"
    ISSUE_NUMBER="${ISSUE_URL##*/}"
    echo "Created issue #${ISSUE_NUMBER}: ${TITLE}"
  fi
done
