# GitHub Workflows

`.github/workflows/` 의 진입점. 워크플로우를 추가하거나 수정하기 전에 이 파일을 먼저 읽고 prefix 컨벤션을 따른다.

## 배경

기존 파일명·`name:` 규칙이 제각각이었다 (`auto-format.yml`, `Deploy to Vercel`, `Hourly: DB Invariant Monitor`, ...). PR Checks 화면에서 *"이게 머지를 막는 건지 / 배포인지 / 단순 자동화인지"* 한눈에 안 잡힘. **"빨갛게 뜨면 무슨 일이 일어나나"** 를 축으로 7 개 prefix 로 통일했다.

## Prefix

| Prefix | 빨갛게 뜨면 = | 예시 파일 |
|---|---|---|
| `pr-gate-` | **머지 못 함** (required check) | `pr-gate.yml` |
| `deploy-` | 사용자·dev 환경에 코드·스키마·시드가 안 갔음 | `deploy-vercel`, `deploy-supabase`, `deploy-android-user`, `deploy-ios-user`, `deploy-dev-seed` |
| `monitor-` | 운영·테스트 시스템 헬스 이상 (스케줄) | `monitor-db-invariants`, `monitor-tick-user`, `monitor-daily-lifecycle`, `monitor-allure` |
| `sync-` | repo 에 자동 commit/push 가 실패함 | `sync-format`, `sync-version`, `sync-graphify`, `sync-mds-mockups`, `sync-pr-branches` |
| `triage-` | PR·이슈 라벨·머지·검증 자동화 실패 (commit 없음) | `triage-label`, `triage-secret-scan`, `triage-review`, `triage-dependabot`, `triage-mds-issue` |
| `tool-` | (수동으로 부를 때만 도는 도구) | (현재 없음 — 새 수동 도구 추가 시 prefix) |
| `shared-` | (다른 워크플로우의 부품 — 단독 실행 X) | `shared-notify`, `shared-android-deploy` |

## 컨벤션

- **파일명 = workflow `name:` 필드** (소문자 kebab, 확장자 제외). 예: `deploy-vercel.yml` 의 `name: deploy-vercel`.
- prefix 다음은 *대상*만 적는다. 액션 동사는 prefix 가 이미 함의함 (`deploy-vercel` ◯ / `deploy-to-vercel` ✗).
- 새 워크플로우는 위 7 prefix 중 하나에 반드시 속해야 한다. 어디에도 안 맞으면 새 prefix 추가 PR 을 먼저 낸다.
- `sync-` vs `triage-` 의 기준: **repo 에 commit 이 들어가나** = `sync-`, 라벨·이슈·검증만 = `triage-`.

## 관련

- [BLUEDOC](../../docs/infra/bluedoc/BLUEDOC.md) — 본 파일이 따르는 진입점 컨벤션
- [CLAUDE.md](../../CLAUDE.md) `## PR Conventions` — required check (`ci-result` job = `pr-gate.yml` 내부) / auto-merge 흐름
