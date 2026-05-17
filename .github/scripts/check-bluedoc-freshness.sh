#!/usr/bin/env bash
# check-bluedoc-freshness.sh
#
# 두 가지 검사:
#   1. Freshness: PR 에서 새 파일/폴더 추가 또는 파일 삭제가 있으면, 그 변경의
#      가장 가까운 (변경 전부터 존재하던) 조상 BLUEDOC.md 가 PR 의 변경 파일 목록에
#      포함돼야 한다.
#   2. Format: 모든 BLUEDOC.md 가 마지막 부분에
#      `_Reviewed: YYYY-MM-DD HH:MM_` 형식의 줄을 포함해야 한다.
#
# 검사 (1) 의 가장 가벼운 통과 방법은 BLUEDOC 의 Reviewed 날짜 bump.
# (이정표 갱신이 정말 필요한지 reviewer 가 판단 → 필요하면 표 갱신, 아니면 날짜만 bump.)
#
# Usage: bash .github/scripts/check-bluedoc-freshness.sh
#        BASE_REF=origin/main bash .github/scripts/check-bluedoc-freshness.sh

set -euo pipefail

BASE_REF="${BASE_REF:-origin/dev}"
FORMAT_RE='^_Reviewed:[[:space:]]+[0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]+[0-9]{2}:[0-9]{2}_$'

# ===== 1. Freshness 검사 =====

ADDED=$(git diff --name-only --diff-filter=AR -M "${BASE_REF}...HEAD" || true)
DELETED=$(git diff --name-only --diff-filter=D -M "${BASE_REF}...HEAD" || true)
ALL_CHANGED=$(git diff --name-only "${BASE_REF}...HEAD" || true)

# BLUEDOC.md 자체 추가/삭제는 검사 대상에서 제외
filter_bluedoc() { grep -v 'BLUEDOC\.md$' || true; }

CHANGES=$(printf '%s\n%s\n' "${ADDED}" "${DELETED}" | filter_bluedoc | grep -v '^$' | sort -u || true)
CHANGED_BLUEDOCS=$(echo "${ALL_CHANGED}" | grep 'BLUEDOC\.md$' | sort -u || true)

declare -a FRESHNESS_VIOLATIONS=()

if [ -n "${CHANGES}" ]; then
    for path in ${CHANGES}; do
        parent=$(dirname "${path}")
        while :; do
            [ "${parent}" = "." ] && break
            [ "${parent}" = "/" ] && break

            if git cat-file -e "${BASE_REF}:${parent}" 2>/dev/null; then
                bluedoc="${parent}/BLUEDOC.md"
                if [ -f "${bluedoc}" ]; then
                    if ! echo "${CHANGED_BLUEDOCS}" | grep -qx "${bluedoc}"; then
                        FRESHNESS_VIOLATIONS+=("${path} → ${bluedoc} not updated")
                    fi
                    break
                fi
            fi
            parent=$(dirname "${parent}")
        done
    done
fi

# ===== 2. Format 검사 =====

declare -a FORMAT_VIOLATIONS=()
while IFS= read -r bluedoc; do
    [ -z "${bluedoc}" ] && continue
    if ! grep -qE "${FORMAT_RE}" "${bluedoc}"; then
        FORMAT_VIOLATIONS+=("${bluedoc}: 마지막에 '_Reviewed: YYYY-MM-DD HH:MM_' 줄이 없거나 형식 불일치")
    fi
done < <(find . -name 'BLUEDOC.md' \
    -not -path './.git/*' \
    -not -path './node_modules/*' \
    -not -path './graphify-out/*' \
    -not -path './build/*' \
    -not -path '*/build/*' \
    | sort)

# ===== 결과 =====

FAIL=0

if [ ${#FRESHNESS_VIOLATIONS[@]} -gt 0 ]; then
    FAIL=1
    mapfile -t UNIQ_FRESH < <(printf '%s\n' "${FRESHNESS_VIOLATIONS[@]}" | sort -u)
    echo "::error::Freshness 위반 (${#UNIQ_FRESH[@]}): 새/삭제 파일에 대해 가장 가까운 ancestor BLUEDOC.md 가 PR 에 포함돼야 합니다."
    for v in "${UNIQ_FRESH[@]}"; do
        echo "  - ${v}"
    done
    echo ""
    echo "통과 방법 (먼저 (1) 부터 검토):"
    echo "  1. 추가/삭제된 파일·폴더가 이정표 표에 들어가야 하면 → BLUEDOC.md 갱신 후 '_Reviewed_' 날짜 bump"
    echo "  2. 변경이 signpost 에 무관하면 → '_Reviewed_' 날짜만 bump (검토했다는 표시)"
    echo ""
fi

if [ ${#FORMAT_VIOLATIONS[@]} -gt 0 ]; then
    FAIL=1
    echo "::error::Format 위반 (${#FORMAT_VIOLATIONS[@]}): BLUEDOC.md 마지막에 '_Reviewed: YYYY-MM-DD HH:MM_' 줄이 있어야 합니다."
    for v in "${FORMAT_VIOLATIONS[@]}"; do
        echo "  - ${v}"
    done
    echo ""
fi

if [ "${FAIL}" = "1" ]; then
    exit 1
fi

echo "✅ BLUEDOC freshness + format OK (${BASE_REF} → HEAD)"
