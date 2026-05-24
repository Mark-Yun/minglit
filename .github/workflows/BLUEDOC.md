# GitHub Workflows

`.github/workflows/` 의 진입점. 워크플로우를 추가하거나 수정하기 전에 이 파일을 먼저 읽고 prefix 컨벤션을 따른다.

## 배경

기존 파일명·`name:` 규칙이 제각각이었다 (`auto-format.yml`, `Deploy to Vercel`, `Hourly: DB Invariant Monitor`, ...). PR Checks 화면에서 *"이게 머지를 막는 건지 / 배포인지 / 단순 자동화인지"* 한눈에 안 잡힘. **"빨갛게 뜨면 무슨 일이 일어나나"** 를 축으로 prefix 를 통일했다.

## Prefix

| Prefix | 빨갛게 뜨면 = | 예시 파일 |
|---|---|---|
| `pr-gate-` | **머지 못 함** (required check — Gitleaks 시크릿 검사 포함) | `pr-gate.yml`, `pr-gate-fresh-doc.yml` |
| `pr-setup-` | PR push 마다 PR 브랜치를 mutate 하는 자동화 (포맷 등) | (현재 없음 — `pr-setup-format` 은 #2627 에서 `pr-gate-format-check` 잡으로 대체) |
| `pr-review-setup-` | PR 의 "리뷰 준비" 자동화 — auto-merge enable + 조건 충족 시 `needs-review` 라벨 부여 | `pr-review-setup` |
| `deploy-` | 사용자·dev 환경에 코드·스키마·시드가 안 갔음 | `deploy-vercel`, `deploy-supabase`, `deploy-android-user`, `deploy-ios-user`, `deploy-dev-seed` |
| `monitor-` | 운영·테스트 시스템 헬스 이상 / 스케줄 유지보수 | `monitor-db-invariants`, `monitor-event-flow-hourly`, `monitor-event-flow-daily`, `monitor-mds-render-coverage`, `monitor-patrol-e2e`, `monitor-allure`, `monitor-build-retention`, `monitor-security-advisor`, `monitor-doc-freshness` |
| `sync-` | repo 에 자동 commit/push 가 실패함 (dev push 또는 merge 기반) | `sync-version`, `sync-graphify`, `sync-mds-mockups`, `sync-pr-branches`, `sync-test-coverage` |
| `set-` | GitHub status/metadata 를 쓰는 수동·자동 API entrypoint 실패 | `set-dev-soak-status`, `set-rc-soak-status` |
| `triage-` | 이슈 생성·슬래시 명령 (commit 없음) | `triage-mds-issue`, `triage-slash` |
| `post-merge` | dev push 직후 follow-up 자동화의 단일 entry point (5 reusable orchestrator) | `post-merge` |
| `tool-` | (수동으로 부를 때만 도는 도구) | (현재 없음 — 새 수동 도구 추가 시 prefix) |
| `shared-` | (다른 워크플로우의 부품 — 단독 실행 X) | `shared-notify`, `shared-android-deploy`, `shared-set-commit-status`, `shared-soak-gate` |
| branch-strategy stage name | branch-strategy 문서의 stage entry workflow | `dev-staging-pr-gate`, `dev-staging-dev-cut-gate`, `dev-staging-dev-cut`, `dev-pr-gate`, `dev-rc-cut-gate`, `dev-rc-cut`, `rc-pr-gate`, `rc-main-cut-gate`, `rc-main-cut`, `main-pr-gate` |
| reusable no-prefix | `workflow_call` 로만 호출되는 domain reusable | `version-bump` |

## Reusable Gates

- `pr-gate.yml` 은 `workflow_call` 전용 reusable CI core 다. 직접 `push`/`pull_request`/`merge_group` 로 실행하지 않는다.
- 호출자는 `stage` (`dev-staging`, `dev`, `rc`, `main`) 와 `base_ref` 를 넘겨 동일한 CI 코어를 stage 별 gate 로 재사용한다.
- `pr-gate.yml` 의 `build-demo-android` 잡은 `minglit_demo`, `main_demo.dart`, Android demo flavor 변경 시 양 앱 demo debug APK 빌드를 검증한다.
- Branch ruleset 의 required check 는 `dev-staging-pr-gate`, `dev-pr-gate`, `rc-pr-gate`, `main-pr-gate` 같은 branch별 wrapper job 이름을 사용한다. `ci-result` summary job 은 폐기한다.
- `dev-staging-pr-gate`, `dev-pr-gate`, `rc-pr-gate`, `main-pr-gate` 는 얇은 wrapper 로 시작한다. 내부에서는 `pr-gate.yml` reusable core 를 호출하고, wrapper job 이 최종 required check context 를 제공한다.
- `dev-staging-dev-cut-gate` 가 dev-staging 의 PR-number CalVer bump/tag 를 담당한다. `sync-version` 은 legacy main release bump 만 담당하며, `dev` promotion 은 `dev-staging-dev-cut` 에서 version 변경 없이 처리한다.
- `dev-rc-cut-gate` 는 cut 직전 evaluator 다. 내부에서 `shared-soak-gate` 를 호출해 `dev-soak/*` status 와 monitor run history 를 확인하고, 통과한 commit 에만 `dev-rc-cut-pass` status 를 찍는다.
- `dev-rc-cut` 은 latest `dev-rc-cut-pass` dev commit 에서 `rc/YYYY-Wxx` branch 를 만들고 `version-bump` 로 `v*-rc-01` + `promo/rc-*` tag 를 생성한다.
- `rc-main-cut-gate` 는 5일 soak 를 통과한 `rc/*` 에 `rc-main-cut-pass` 를 찍고, `rc-main-cut` 은 그 marker 를 소비해 `main` PR 을 만든다.
- deploy entry 는 후속 단계에서 `[branch]-deploy` 로 통일한다 (`dev-deploy`, `rc-deploy`, `main-deploy`). `monitor-event-flow-*` 는 deploy 가 아니라 지속 batch signal 이다.
- `set-dev-soak-status` / `set-rc-soak-status` 는 workflow 와 AI agent 가 사용하는 공개 status write API 다. 내부에서는 `shared-set-commit-status` 를 호출한다.
- protected branch/tag 에 직접 push 하는 workflow 는 `minglit-release-bot` GitHub App token 을 사용한다. App credential 은 `minglit_env/{stage}/github.env` 파일에서 먼저 읽고, 공통 token mint 는 `.github/actions/release-bot-token` 에서 처리한다.

## 컨벤션

- **파일명 = workflow `name:` 필드** (소문자 kebab, 확장자 제외). 예: `deploy-vercel.yml` 의 `name: deploy-vercel`.
- prefix 다음은 *대상*만 적는다. 액션 동사는 prefix 가 이미 함의함 (`deploy-vercel` ◯ / `deploy-to-vercel` ✗).
- 새 entry workflow 는 위 prefix 중 하나에 반드시 속해야 한다. 단, branch-strategy 문서에서 고정한 stage entry workflow 는 문서명과 같은 이름을 허용한다.
- `workflow_call` 전용 reusable 은 domain name no-prefix 를 허용한다.
- `shared-` reusable 은 사람이 직접 실행하지 않는다. 수동 실행이 필요하면 `set-`/`tool-` entry workflow 를 따로 둔다.
- `pr-setup-` vs `pr-review-setup-` vs `sync-` vs `triage-` 의 기준:
  - `pr-setup-` = PR push 마다 PR 브랜치를 mutate (#2627 이후 인스턴스 없음 — auto-format 은 `pr-gate` 의 `format-check` 잡으로 대체)
  - `pr-review-setup-` = PR 의 "리뷰 준비 단계" 자동화 (auto-merge enable, `needs-review` 라벨 부여)
  - `sync-` = dev push 또는 merge 기반으로 repo 에 commit 을 자동 push
  - `triage-` = 이슈 생성·슬래시 명령 (commit 없음, PR 외 컨텍스트에서도 동작)

## 관련

- [BLUEDOC](../../docs/infra/bluedoc/BLUEDOC.md) — 본 파일이 따르는 진입점 컨벤션
- [CLAUDE.md](../../CLAUDE.md) `## PR Conventions` — branch별 required check / auto-merge 흐름

---
_Reviewed: 2026-05-24 16:45_
