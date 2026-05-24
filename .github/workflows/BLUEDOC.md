# GitHub Workflows

`.github/workflows/` 의 진입점. 워크플로우를 추가하거나 수정하기 전에 이 파일을 먼저 읽고 prefix 컨벤션을 따른다.

## 배경

기존 파일명·`name:` 규칙이 제각각이었다 (`auto-format.yml`, `Deploy to Vercel`, `Hourly: DB Invariant Monitor`, ...). PR Checks 화면에서 *"이게 머지를 막는 건지 / 배포인지 / 단순 자동화인지"* 한눈에 안 잡힘. **"빨갛게 뜨면 무슨 일이 일어나나"** 를 축으로 9 개 prefix 로 통일했다.

## Prefix

| Prefix | 빨갛게 뜨면 = | 예시 파일 |
|---|---|---|
| `pr-gate-` | **머지 못 함** (required check — Gitleaks 시크릿 검사 포함) | `pr-gate.yml`, `pr-gate-fresh-doc.yml` |
| `pr-setup-` | PR push 마다 PR 브랜치를 mutate 하는 자동화 (포맷 등) | (현재 없음 — `pr-setup-format` 은 #2627 에서 `pr-gate-format-check` 잡으로 대체) |
| `pr-review-setup-` | PR 의 "리뷰 준비" 자동화 — auto-merge enable + 조건 충족 시 `needs-review` 라벨 부여 | `pr-review-setup` |
| `deploy-` | 사용자·dev 환경에 코드·스키마·시드가 안 갔음 | `deploy-vercel`, `deploy-supabase`, `deploy-android-user`, `deploy-ios-user`, `deploy-dev-seed` |
| `monitor-` | 운영·테스트 시스템 헬스 이상 / 스케줄 유지보수 | `monitor-db-invariants`, `monitor-event-flow-hourly`, `monitor-event-flow-daily`, `monitor-mds-render-coverage`, `monitor-patrol-e2e`, `monitor-allure`, `monitor-build-retention`, `monitor-security-advisor`, `monitor-doc-freshness` |
| `sync-` | repo 에 자동 commit/push 가 실패함 (dev push 또는 merge 기반) | `sync-version`, `sync-graphify`, `sync-mds-mockups`, `sync-pr-branches`, `sync-test-coverage` |
| `triage-` | 이슈 생성·슬래시 명령 (commit 없음) | `triage-mds-issue`, `triage-slash` |
| `post-merge` | dev push 직후 follow-up 자동화의 단일 entry point (5 reusable orchestrator) | `post-merge` |
| `tool-` | (수동으로 부를 때만 도는 도구) | (현재 없음 — 새 수동 도구 추가 시 prefix) |
| `shared-` | (다른 워크플로우의 부품 — 단독 실행 X) | `shared-notify`, `shared-android-deploy` |
| branch-strategy stage name | branch-strategy 문서의 stage entry workflow | `dev-staging-post-merge-sync`, `nightly-cut`, `rc-gate`, `rc-cut` |
| reusable no-prefix | `workflow_call` 로만 호출되는 domain reusable | `version-bump` |

## Reusable Gates

- `pr-gate.yml` 은 기존 `push`/`pull_request`/`merge_group` 진입점을 유지하면서 `workflow_call` 도 지원한다.
- 호출자는 `stage` (`dev`, `dev-staging`, `nightly`, `rc`, `main`) 와 `base_ref` 를 넘겨 동일한 CI 코어를 stage 별 gate 로 재사용한다.
- 기존 required check 는 아직 `ci-result` 그대로 유지한다. stage 별 required check 전환은 branch-strategy Phase 4 에서 Ruleset 과 함께 적용한다.
- `dev-staging-post-merge-sync` 가 dev-staging 의 PR-number CalVer bump/tag 를 담당한다. `sync-version` 은 legacy main release bump 만 담당하며, `dev` promotion 은 `nightly-cut` 에서 version 변경 없이 처리한다.
- `rc-gate` 는 dev push 후 user/partner CUJ integration 을 직접 실행하고, 통과한 commit 에만 `rc-gate-pass` status 를 찍는다. backend/EF/Test Lab 을 포함한 full `rc-gate-suite` matrix 는 후속 확장이다.
- `rc-cut` 은 latest `rc-gate-pass` dev commit 에서 `rc/YYYY-Www` branch 를 만들고 `version-bump` 로 `v*-rc-01` + `promo/rc-*` tag 를 생성한다.
- protected branch/tag 에 직접 push 하는 workflow 는 `minglit-release-bot` GitHub App token 을 사용한다. App credential 은 `minglit_env/{stage}/github.env` 파일에서 먼저 읽고, 공통 token mint 는 `.github/actions/release-bot-token` 에서 처리한다.

## 컨벤션

- **파일명 = workflow `name:` 필드** (소문자 kebab, 확장자 제외). 예: `deploy-vercel.yml` 의 `name: deploy-vercel`.
- prefix 다음은 *대상*만 적는다. 액션 동사는 prefix 가 이미 함의함 (`deploy-vercel` ◯ / `deploy-to-vercel` ✗).
- 새 entry workflow 는 위 9 prefix 중 하나에 반드시 속해야 한다. 단, branch-strategy 문서에서 고정한 stage entry workflow 는 문서명과 같은 이름을 허용한다.
- `workflow_call` 전용 reusable 은 domain name no-prefix 를 허용한다.
- `pr-setup-` vs `pr-review-setup-` vs `sync-` vs `triage-` 의 기준:
  - `pr-setup-` = PR push 마다 PR 브랜치를 mutate (#2627 이후 인스턴스 없음 — auto-format 은 `pr-gate` 의 `format-check` 잡으로 대체)
  - `pr-review-setup-` = PR 의 "리뷰 준비 단계" 자동화 (auto-merge enable, `needs-review` 라벨 부여)
  - `sync-` = dev push 또는 merge 기반으로 repo 에 commit 을 자동 push
  - `triage-` = 이슈 생성·슬래시 명령 (commit 없음, PR 외 컨텍스트에서도 동작)

## 관련

- [BLUEDOC](../../docs/infra/bluedoc/BLUEDOC.md) — 본 파일이 따르는 진입점 컨벤션
- [CLAUDE.md](../../CLAUDE.md) `## PR Conventions` — required check (`ci-result` job = `pr-gate.yml` 내부) / auto-merge 흐름

---
_Reviewed: 2026-05-24 09:24_
