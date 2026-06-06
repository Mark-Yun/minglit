# GitHub Workflows

`.github/workflows/` 의 진입점. 워크플로우를 추가하거나 수정하기 전에 이 파일을 먼저 읽고 prefix 컨벤션을 따른다.

## 배경

기존 파일명·`name:` 규칙이 제각각이었다 (`auto-format.yml`, `Deploy to Vercel`, `Hourly: DB Invariant Monitor`, ...). PR Checks 화면에서 *"이게 머지를 막는 건지 / 배포인지 / 단순 자동화인지"* 한눈에 안 잡힘. **"빨갛게 뜨면 무슨 일이 일어나나"** 를 축으로 prefix 를 통일했다.

## Prefix

| Prefix | 빨갛게 뜨면 = | 예시 파일 |
|---|---|---|
| `pr-gate-` | **머지 못 함** (required check — static PR 메시지 검사 + Gitleaks 시크릿 검사 포함) | `pr-gate.yml`, `pr-gate-fresh-doc.yml` |
| `pr-setup-` | PR push 마다 PR 브랜치를 mutate 하는 자동화 (포맷 등) | (현재 없음 — `pr-setup-format` 은 #2627 에서 `pr-gate-format-check` 잡으로 대체) |
| `pr-review-setup-` | PR 의 "리뷰 준비" 자동화 — auto-merge enable + 조건 충족 시 `needs-review` 라벨 부여 | `pr-review-setup` |
| `deploy-` | 사용자·dev 환경에 코드·스키마·시드가 안 갔음 | `dev-deploy`, `main-deploy`, `deploy-vercel`, `deploy-supabase`, `deploy-dev-event-flow-cron`, `deploy-android-user`, `deploy-ios-user`, `deploy-dev-seed` |
| `monitor-` | 운영·테스트 시스템 헬스 이상 / 스케줄 유지보수 | `monitor-dev-staging-health`, `monitor-dev-cuj`, `monitor-db-invariants`, `monitor-event-flow-distributed`, `monitor-event-flow-hourly`, `monitor-event-flow-daily`, `monitor-mds-render-coverage`, `monitor-patrol-e2e`, `monitor-allure`, `monitor-build-retention`, `monitor-security-advisor`, `monitor-doc-freshness` |
| `sync-` | repo 에 자동 commit/push 가 실패함 (dev-staging push 또는 merge 기반) | `sync-graphify`, `sync-mds-mockups`, `sync-pr-branches`, `sync-test-coverage` |
| `set-` | GitHub status/metadata 를 쓰는 수동·자동 API entrypoint 실패 | `set-dev-soak-status`, `set-rc-soak-status` |
| `triage-` | 이슈 생성·슬래시 명령 (commit 없음) | `triage-mds-issue`, `triage-slash` |
| `post-merge` | dev-staging push 직후 일반 PR flow follow-up 자동화의 단일 entry point | `post-merge` |
| `tool-` | (수동으로 부를 때만 도는 도구) | (현재 없음 — 새 수동 도구 추가 시 prefix) |
| `shared-` | (다른 워크플로우의 부품 — 단독 실행 X) | `shared-notify`, `shared-android-deploy`, `shared-ios-deploy`, `shared-vercel-deploy`, `shared-set-commit-status`, `shared-soak-gate`, `shared-promo-tag`, `shared-pr-source-guard` |
| branch-strategy stage name | branch-strategy 문서의 stage entry workflow | `dev-staging-pr-gate`, `dev-staging-dev-cut-gate`, `dev-staging-dev-cut`, `dev-pr-gate`, `dev-rc-cut-gate`, `dev-rc-cut`, `rc-pr-gate`, `rc-main-cut-gate`, `rc-main-cut`, `main-pr-gate` |
| reusable no-prefix | `workflow_call` 로만 호출되는 domain reusable | `version-bump` |
| event utility | 특정 GitHub event 에 반응해 release bookkeeping 을 정리 | `close-cut-issue-on-pr-merge` |

## Reusable Gates

- `pr-gate.yml` 은 `workflow_call` 전용 reusable CI core 다. 직접 `push`/`pull_request`/`merge_group` 로 실행하지 않는다.
- 호출자는 `stage` (`dev-staging`, `dev`, `rc`, `main`) 와 `base_ref` 를 넘겨 동일한 CI 코어를 stage 별 gate 로 재사용한다.
- `pr-gate.yml` 의 `build-demo-android` 잡은 `minglit_demo`, `main_demo.dart`, Android demo flavor 변경 시 양 앱 demo debug APK 빌드를 검증한다.
- Branch ruleset 의 required check 는 `dev-staging-pr-gate`, `dev-pr-gate`, `rc-pr-gate`, `main-pr-gate` 같은 branch별 wrapper job 이름을 사용한다. `ci-result` summary job 은 폐기한다.
- `dev-staging-pr-gate`, `dev-pr-gate`, `rc-pr-gate`, `main-pr-gate` 는 얇은 wrapper 로 시작한다. 내부에서는 `pr-gate.yml` reusable core 를 호출하고, wrapper job 이 최종 required check context 를 제공한다.
- `dev-pr-gate`, `rc-pr-gate`, `main-pr-gate` 는 `shared-pr-source-guard` 로 직접 PR 을 차단한다. 정상 진입점은 `dev-staging` 이고, 예외는 branch별 approved hotfix 뿐이다.
- `monitor-dev-staging-health` 는 required check 가 아니다. 6시간마다 `dev-staging` HEAD 에서 EF unit/integration 중심으로 nightly 전 회귀를 발견하고, 결과를 `dev-staging-health/*` commit status 로 남긴다.
- `monitor-dev-cuj` 는 Flutter 모바일 동결(웹 MVP 피벗)로 disable 대상이다. 활성 시절에는 `dev` push 마다 user/partner CUJ 를 실행하고 `dev-soak/cuj-*` status 와 실패 이슈를 남겼다.
- `dev-staging-dev-cut-gate` 는 수동 candidate inspect 전용이며 per-merge mutation 을 하지 않는다. 날짜 기반 dev-staging version bump/tag 는 하루 1회 `dev-staging-dev-cut` 이 직접 수행한다.
- `dev-staging-dev-cut` 은 release bot 으로 protected `dev-staging` 에 version bump commit 을 fast-forward push 하고 `vYY.MM.DD+YYMMDDNN-dev-staging` tag 를 만든 뒤, 해당 tag SHA 를 `dev` 로 promote 한다. `dev`/`rc`/`main` promotion 은 source-controlled version 변경 없이 처리한다.
- `dev-rc-cut-gate` 는 cut 직전 evaluator 다. 내부에서 `shared-soak-gate` 를 호출해 legacy `dev-soak/*` health status 와 `deploy-dev-event-flow-cron` same-SHA run evidence 를 확인하고, 통과한 commit 에만 `dev-rc-cut-pass` status 를 찍는다 (모바일 동결로 CUJ run requirement 는 제거, `dev-soak/cuj-*` failure 는 수동 block lever 로 유지).
- Release gate 는 true evidence 기반이다. required success status/run history/git lineage 가 없으면 `unknown` 이며, failure issue 가 없다는 이유만으로 `dev-rc-cut-pass` 또는 `rc-main-cut-pass` 를 쓰지 않는다.
- `dev-rc-cut` 은 latest `dev-rc-cut-pass` dev commit 에서 `rc/YYYY-Wxx` branch 를 만들고 `promo/rc-*` tag 를 생성한다. RC branch 에 version bump commit 을 만들지 않는다.
- `dev-rc-cut` 은 active RC 가 있으면 기본 skip 한다. active RC 는 1개만 유지하고, 예외는 release-manager override 로만 허용한다.
- `rc-main-cut-gate` 는 5일 soak, required RC success evidence, pre-main validation, dev-staging-first hotfix lineage 를 통과한 `rc/*` 에만 `rc-main-cut-pass` 를 찍고, `rc-main-cut` 은 그 marker 를 소비해 `main` PR 을 만든다.
- RC hotfix 는 dev-staging-first 다. fix 를 먼저 dev-staging 에 머지하고, active RC 에는 같은 commit/snapshot 을 `rc-hotfix-apply`/cherry-pick PR 로 반영한다. RC-only 선머지는 release-manager override 가 필요한 예외다.
- `.github/actions/cut-issue` 는 cut-gate tracking issue 를 생성/갱신/닫는 composite action 이다. Issue 는 운영자가 보는 추적 surface 이며 gate 판정 SSOT 는 commit status/workflow result 다.
- `close-cut-issue-on-pr-merge` 는 promotion PR body 의 `minglit:cut-issue-number` marker 를 보고 PR merge 시 해당 cut issue 를 닫는다.
- `dev-deploy` 는 dev push 후 web dev 배포만 orchestrate 한다. 모바일(android/ios) 배포는 웹 MVP 피벗으로 동결 — `deploy-android-*`/`deploy-ios-*` adapter 는 남아 있지만 호출자가 없다.
- `main-deploy` 는 main push 후 prod web 배포를 orchestrate 한다 (모바일 동결). version bump commit 없이 deploy-time metadata 를 계산하고 `shared-promo-tag` 로 `promo/main-*` marker 를 만든다.
- `shared-ios-deploy` 는 App Store Connect 업로드 SDK 요구사항 때문에 `macos-26` runner 에 고정한다. 회귀 검사는 `.github/scripts/check-ios-deploy-branch-conditions.sh` 가 담당한다.
- `shared-promo-tag` 는 `promo/rc-*`, `promo/main-*` tag 생성의 공통 release-bot 구현이다. Concrete workflow 는 target ref, tag name, commit SHA 만 넘긴다.
- `deploy-dev-event-flow-cron` 은 `dev` push 에서만 dev Supabase `dev-event-flow-simulator` pg_cron 을 설치한다. `monitor-event-flow-distributed` 는 `--ref dev` 수동 smoke 전용이고, hourly/daily 는 legacy manual smoke 다.
- `deploy-android-*`, `deploy-ios-*`, `deploy-vercel` 은 branch-level deploy 에서 호출하는 concrete adapter 다. 직접 push/schedule 로 실행하지 않는다.
- 실제 build/upload/notify 로직은 각각 `shared-android-deploy`, `shared-ios-deploy`, `shared-vercel-deploy` 에 둔다.
- 모바일 배포 산출물(APK/AAB/IPA)은 GitHub Release asset 으로 보관한다. Actions artifact 는 테스트/디버깅 산출물용이며, deploy archive 의 source-of-truth 로 쓰지 않는다.
- deploy entry 는 후속 단계에서 `[branch]-deploy` 로 통일한다 (`dev-deploy`, `rc-deploy`, `main-deploy`). `monitor-event-flow-*` 는 deploy 가 아니라 지속 batch signal 이다.
- `set-dev-soak-status` / `set-rc-soak-status` 는 workflow 와 AI agent 가 사용하는 공개 status write API 다. `dev-soak/*` prefix 는 dev health 의 legacy compatibility context 이며, 내부에서는 `shared-set-commit-status` 를 호출한다.
- protected branch/tag 에 직접 push 하는 workflow 는 `minglit-release-bot` GitHub App token 을 사용한다. App credential 은 `minglit_env/{stage}/github.env` 파일에서 먼저 읽고, 공통 token mint 는 `.github/actions/release-bot-token` 에서 처리한다.
- `version-bump` 는 source-controlled version file 변경용 reusable/legacy building block 이다. active dev-staging daily cut 은 `dev-staging-dev-cut` 안에서 `scripts/bump-version.sh` 를 직접 실행한다.
- 앱 deploy version 은 `shared-version-metadata` 가 latest dev-staging snapshot build number 를 찾아 Android/iOS build command 에 주입한다.

## 컨벤션

- **파일명 = workflow `name:` 필드** (소문자 kebab, 확장자 제외). 예: `deploy-vercel.yml` 의 `name: deploy-vercel`.
- prefix 다음은 *대상*만 적는다. 액션 동사는 prefix 가 이미 함의함 (`deploy-vercel` ◯ / `deploy-to-vercel` ✗).
- 새 entry workflow 는 위 prefix 중 하나에 반드시 속해야 한다. 단, branch-strategy 문서에서 고정한 stage entry workflow 는 문서명과 같은 이름을 허용한다.
- `workflow_call` 전용 reusable 은 domain name no-prefix 를 허용한다.
- `shared-` reusable 은 사람이 직접 실행하지 않는다. 수동 실행이 필요하면 `set-`/`tool-` entry workflow 를 따로 둔다.
- `pr-setup-` vs `pr-review-setup-` vs `sync-` vs `triage-` 의 기준:
  - `pr-setup-` = PR push 마다 PR 브랜치를 mutate (#2627 이후 인스턴스 없음 — auto-format 은 `pr-gate` 의 `format-check` 잡으로 대체)
  - `pr-review-setup-` = PR 의 "리뷰 준비 단계" 자동화 (auto-merge enable, `needs-review` 라벨 부여)
  - `sync-` = dev-staging push 또는 merge 기반으로 repo 에 commit 을 자동 push
  - `triage-` = 이슈 생성·슬래시 명령 (commit 없음, PR 외 컨텍스트에서도 동작)

## 관련

- [BLUEDOC](../../docs/infra/bluedoc/BLUEDOC.md) — 본 파일이 따르는 진입점 컨벤션
- [CLAUDE.md](../../CLAUDE.md) `## PR Conventions` — branch별 required check / auto-merge 흐름

---
_Reviewed: 2026-06-04 07:16_
