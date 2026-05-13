# 테스트 계획

본 시스템의 동작을 보장하는 테스트 범위. validator 와 GitHub 워크플로우 두 축으로 나눈다.

## Validator 단위 테스트

`scripts/fresh-doc-lint.ts` 의 Deno test. 위치: `scripts/__tests__/fresh-doc-lint.test.ts`.

### Schema 검증 케이스

각 검증 규칙마다 valid / invalid 케이스 1개씩 fixture 로 작성한다.

| 규칙 | Valid | Invalid |
|------|-------|---------|
| 트리거 배타 | `cycle` 단독 / `watched_paths` 단독 | 둘 다 지정 / 둘 다 없음 |
| `priority` enum | `P3-low` | `P5-low`, 누락 |
| `last_verified` 포맷 | `2026-05-13` | `2026-5-13`, `2026/05/13`, 미래 날짜 |
| `cycle` 포맷 | `30d` | `30 days`, `30D`, `1m` |
| `recursive` 타입 | `true` / `false` / 미지정 | `"true"`, `1` |

### 참조 검증 케이스

- `exclude` glob 이 0건 매칭 → 경고 출력 (종료 코드 0)
- `watched_paths` 경로가 레포에 존재하지 않음 → 에러 (종료 코드 2)
- 디렉토리에 `.md` 가 0개 (`exclude` 적용 후) → 에러

### Dry-run 출력

오늘 날짜를 주입 가능하게 (`--today=YYYY-MM-DD` 플래그) 만들어 stale / fresh 판정 출력 형식을 스냅샷 테스트로 비교한다.

## 워크플로우 테스트

GitHub Actions 워크플로우 자체는 통합 테스트로 검증한다.

### 단위 — Stale 판정 로직

워크플로우 내부의 판정 로직을 별도 스크립트로 분리한 뒤 (`scripts/fresh-doc-detect.ts`) Deno test 로 검증:

- `cycle` 기반: 경계 케이스 (`last_verified + cycle == today`, `+1d`, `-1d`)
- `watched_paths` 기반: 매칭 파일 마지막 커밋 timestamp 비교 (모의 git history fixture 사용)

### 통합 — End-to-end

`.github/workflows/doc-freshness-test.yml` (수동 트리거 전용) 로 검증한다.

1. 테스트 fixture 디렉토리에 stale 한 `FRESH_DOC` 배치
2. 워크플로우 실행
3. 생성된 이슈 검증 — 제목 prefix `[doc-refresh]`, 라벨 (`documentation`, priority), 본문 필드 존재
4. 같은 워크플로우 재실행 → dedup 동작 확인 (신규 이슈 0건)
5. 테스트 이슈 자동 정리 (워크플로우 종료 단계에서 `gh issue close`)

## 테스트 Fixtures

`tests/doc-freshness/fixtures/`:

| 경로 | 용도 |
|------|------|
| `valid-cycle/FRESH_DOC` | cycle 기반 정상 케이스 |
| `valid-watched/FRESH_DOC` | watched_paths 기반 정상 케이스 |
| `invalid-both-triggers/FRESH_DOC` | 트리거 둘 다 지정 (실패) |
| `invalid-no-trigger/FRESH_DOC` | 트리거 없음 (실패) |
| `recursive-with-nested/` | recursive: true + 하위에 별도 FRESH_DOC |

## CI 트리거 조건

- **Validator 테스트**: `scripts/fresh-doc-lint.ts` 또는 `docs/**/FRESH_DOC` 변경 시 PR 마다 실행
- **워크플로우 통합 테스트**: 주 1회 (월요일) 스케줄, 또는 `.github/workflows/doc-freshness*.yml` 변경 시
