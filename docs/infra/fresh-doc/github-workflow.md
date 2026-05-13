# 워크플로우 동작

GitHub Actions 워크플로우가 매일 모든 `FRESH_DOC` 을 스캔하여 stale 한 디렉토리에 Issue 를 생성한다. 구현은 `.github/workflows/doc-freshness.yml` (후속 PR).

## 실행 주기

GitHub Actions `schedule:` 트리거 (cron 표현식: `0 0 * * *`). UTC 자정 기준 매일 1회 (KST 09:00). `workflow_dispatch` 로 수동 실행도 지원한다.

## Stale 판정

각 `FRESH_DOC` 의 트리거 필드에 따라 판정한다.

- `cycle` 지정 시: `today - last_verified >= cycle` 이면 stale
- `watched_paths` 지정 시: 매칭되는 경로 중 `last_verified` 이후 커밋이 있으면 stale (`git log --since=<last_verified> -- <path>`)

검사 대상 `.md` 는 디렉토리의 모든 `.md` 에서 `exclude` 매칭분을 제외한다. `recursive: true` 면 하위 디렉토리도 포함하되, 하위에 별도 `FRESH_DOC` 이 있으면 거기서 끊긴다.

## 이슈 생성

stale 디렉토리마다 GitHub Issue 1개를 생성한다.

- 제목: `[doc-refresh] <디렉토리 경로> — 문서 검토 필요`
- 라벨: `documentation`, `FRESH_DOC` 의 `priority` 값
- 본문:
  - 대상 디렉토리 경로
  - 검토 대상 `.md` 파일 목록 (`exclude` 적용 후)
  - 트리거 정보 — `cycle` 인 경우 마지막 검토일과 경과 일수, `watched_paths` 인 경우 트리거된 커밋 해시 목록
  - `refresh_method` 본문 (있을 경우)

## Dedup

동일 디렉토리에 대한 `open` 상태 이슈가 이미 있으면 신규 생성을 skip 한다. 이슈 제목의 `[doc-refresh] <path>` prefix 로 검색한다. 중복 이슈로 인한 노이즈를 막는다.

## last_verified 갱신

워크플로우는 검사만 한다. `last_verified` 갱신은 이슈를 닫는 PR 의 책임이다. 두 경로 중 하나로 처리한다.

- 문서를 실제로 수정한 경우: 수정 사항과 함께 `last_verified` 를 PR 머지 예정일로 갱신
- 검토 결과 변경 불필요한 경우: `last_verified` 만 갱신하는 verified-only PR

후자는 false positive 방지 차원에서도 중요하다. 이벤트 기반(`watched_paths`) 트리거가 코드 변경에 비해 문서 변경 필요성이 낮을 때 자주 발생한다.

## 실패 시 동작

- `FRESH_DOC` 파싱 실패: 워크플로우 단계 실패. 별도 알림 이슈 생성 (라벨 `infra-bug`).
- 이슈 생성 API 실패: 재시도 3회 후 워크플로우 실패. 다음 스케줄 실행에서 자동 재시도.
