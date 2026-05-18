# 워크플로우 동작

GitHub Actions 워크플로우가 매일 모든 `FRESH_DOC` 을 스캔하여 stale 디렉토리에 Issue 를 생성한다. 구현: [`.github/workflows/monitor-doc-freshness.yml`](../../../.github/workflows/monitor-doc-freshness.yml).

## 실행 주기

`schedule:` 트리거 (cron `0 0 * * *`). UTC 자정 = KST 09:00. `workflow_dispatch` 수동 실행도 지원하며 `force=true` 옵션은 stale 무시하고 모든 FRESH_DOC 에 Issue 생성 (bootstrap 용).

## Stale 판정

각 FRESH_DOC 의 스키마 버전 + 트리거 필드에 따라 판정.

### derived `last_verified`

**v2 (target_files)**: 모든 target file 에 대해 `git log -1 --format=%ct -- <file>` 의 최대값 → derived last_verified.

**v1 (last_verified field)**: 필드 값 그대로 사용.

### 트리거별 stale 판정

- **`cycle`**: `today - derived_last_verified >= cycle` 이면 stale
- **`watched_paths`**: 매칭 경로 중 `derived_last_verified` 이후 커밋이 있으면 stale (`git log --since=<derived> -- <path>`)

## 이슈 생성

stale 디렉토리마다 GitHub Issue 1개를 생성.

- 제목: `[doc-refresh] <디렉토리 경로> — 문서 검토 필요`
- 라벨: FRESH_DOC 의 `priority` 값 (예: `P2-medium`)
- 본문:
  - 대상 디렉토리 경로
  - 검토 대상 파일 목록 (v2: `target_files` 글로브 expansion / v1: `recursive`+`exclude` 적용)
  - 트리거 정보 — `cycle` 인 경우 derived last_verified + 경과 일수; `watched_paths` 인 경우 트리거된 커밋 해시
  - `refresh_method` 본문 (있을 경우)

## Dedup

동일 디렉토리 open 이슈가 이미 있으면 신규 생성 skip. 제목 prefix `[doc-refresh] <path>` 로 검색.

## last_verified 갱신

워크플로우는 검사만 한다. last_verified 갱신은:

**v2**: target_files 중 하나라도 변경하는 PR 이 자동으로 reset (git log 자동 derive). PR 작성자가 별도 필드 갱신 필요 없음.

**v1**: 이슈를 닫는 PR 의 `last_verified` 필드 수동 갱신 책임.
- 문서를 실제로 수정한 경우: 수정 사항과 함께 PR 머지 예정일로 갱신
- 검토 결과 변경 불필요: `last_verified` 만 갱신하는 verified-only PR

v1 의 false positive 부담은 v2 마이그레이션으로 해소된다.

## PR-time validator

[`.github/workflows/pr-gate-fresh-doc.yml`](../../../.github/workflows/pr-gate-fresh-doc.yml) 는 PR 의 FRESH_DOC 변경 시 자동으로 [`scripts/fresh-doc-lint.ts`](../../../scripts/fresh-doc-lint.ts) 를 실행해 schema 위반을 차단. 새 FRESH_DOC 작성 / 기존 FRESH_DOC 수정 모두 검증.

## 실패 시 동작

- FRESH_DOC 파싱 실패: 워크플로우 단계 실패. 별도 알림 이슈 생성 (라벨 `infra-bug`).
- 이슈 생성 API 실패: 재시도 3회 후 워크플로우 실패. 다음 스케줄에서 자동 재시도.
