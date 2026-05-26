# Test Strategy

4-stage 모델 (`dev-staging → dev → rc → main`) + flag staged rollout 환경에서, *어떤 테스트가 어느 단계에서 도는가* 의 단일 source. 빠른 검사 = branch별 `*-pr-gate`, 지속 소킹 = `monitor-event-flow-*`/real-device/app AI review, RC 후보 판정 = `dev-rc-cut-gate`, 프로덕션 검증 = `deploy-android-*, deploy-ios-*` smoke + flag staged.

## 단계별 게이트

| 단계 | 게이트 | 소요 | 실패 시 |
|------|--------|------|---------|
| dev-staging 머지 전 | `dev-staging-pr-gate` (unit · lint · analyze · pgTAP · EF test · migration check · `expand-migrate-contract` · `flag-registration` · gitleaks) | < 10분 | auto-merge 보류 |
| dev-staging 머지 후 지속 검증 | `monitor-dev-staging-health` (EF unit/integration + user/partner CUJ) | 6시간마다 | 실패 즉시 issue/notify + `dev-staging-health/*` status |
| dev 머지 전 | `dev-pr-gate` (dev-staging-pr-gate 와 동일 — defensive) | < 10분 | dev-staging-dev-cut PR drop |
| dev 머지 후 24h soak | `monitor-event-flow-*` + real-device/app AI review status writer | 24h | 실패 즉시 `dev-soak/*` failure status + release-blocker issue |
| RC cut 직전 | `dev-rc-cut-gate` evaluator (24h run history + `dev-soak/*` status 확인) | 분 | `dev-rc-cut-pass` 미부여 |
| rc 머지 전 (hotfix) | `rc-pr-gate` (pr-gate + mobile smoke) | < 15분 | hotfix PR drop |
| main 머지 전 (rc → main) | `main-pr-gate` (pr-gate + `expand-migrate-contract` 재검증 + RC HEAD 의 `dev-rc-cut-pass` 확인 + `rc-main-cut-pass` marker 확인) | 분 | promotion PR 보류 |
| rc → main PR | workflow auto-merge (모든 check 통과 시) | 분 | check 실패 시 PR hold + alert |
| main deploy 후 | backend/web/mobile smoke + Sentry/Crashlytics 알람 임계 | 분 | rollback ([main-promotion.md](./main-promotion.md)) |
| deploy-android-*, deploy-ios-* 후 | mobile build smoke (Fastlane upload 검증) | 시간 | retry 1회 → auto-issue + mobile 팀 |
| Flag canary (allowlist) | Statsig metric gates | 며칠 | flag flip OFF |
| Flag staged (5/25/100%) | Statsig one-sided sequential | 48h/72h/7일 | hold or rollback |

## Stage 별 상세

### dev-staging-pr-gate — 빠른 머지 게이트

일반 PR + auto-merge 로 처리한다. base drift 가 생기면 branch update 후 gate 를 재실행한다.

- `test-flutter-apps` (matrix: app_user, app_partner)
- `lint-landing-user`, `lint-landing-partner`
- `test-supabase` (pgTAP)
- `test-edge-functions` (Deno)
- `check-migration-versions`
- **`expand-migrate-contract`** (safety net — DB schema 6-month 호환)
- **`flag-registration-check`** (safety net — 새 코드 path 가 flag SDK 참조)
- `gitleaks`
- CodeRabbit 리뷰 (최대 30분 대기)

룰: 10분 넘으면 `dev-rc-cut-gate` 로 이동.

### monitor-dev-staging-health — 6시간 health monitor

`dev-staging` HEAD 를 하루 4번 검증한다. PR required check 는 아니며, nightly/dev cut 전에 앱/백엔드 계약 회귀를 빨리 발견하기 위한 지속 monitor 다.

- `ef-unit`: Edge Function Deno unit test + EF auth/lint guard
- `ef-integration`: local Supabase + migration-only DB 에서 EF CUJ integration test
- `cuj-user`: app_user emulator CUJ
- `cuj-partner`: app_partner emulator CUJ

결과는 candidate SHA 에 `dev-staging-health/ef-unit`, `dev-staging-health/ef-integration`, `dev-staging-health/cuj-user`, `dev-staging-health/cuj-partner` commit status 로 남긴다. 초기에는 alert/issue 용 signal 로만 사용하고, 안정화 후 `dev-staging-dev-cut-gate` 가 failure status 를 보면 dev promotion 을 보류하도록 연결한다.

### dev-pr-gate

`dev-staging-pr-gate` 와 동일한 test suite. 환경 차이로 인한 회귀만 잡는 defensive 검증. 대부분 통과.

### dev soak signals

dev 에 들어간 latest HEAD 만 RC candidate 로 평가한다. 새 dev commit 이 들어오면 candidate 와 24h soak clock 은 reset 된다.

| Signal | 실행자 | 실패 status | 성공 status |
|--------|--------|-------------|-------------|
| backend simulator | `monitor-event-flow-distributed` (legacy hourly/daily 는 수동 smoke) | `dev-soak/backend-simulator` failure 즉시 | `dev-rc-cut-gate` 가 run history 확인 후 success |
| real device | Test Lab/실디바이스 workflow | `dev-soak/real-device` failure 즉시 | `dev-rc-cut-gate` 가 required signal 확인 후 success |
| app AI review | AI agent | `dev-soak/app-ai-review` failure 즉시 | `dev-rc-cut-gate` 가 pass signal 확인 후 success |

### dev-rc-cut-gate — Evaluator

cut 직전 schedule/manual 로 실행한다. 통과 시 commit 에 GitHub status `dev-rc-cut-pass` 를 set 한다.

- candidate age >= 24h
- `monitor-event-flow-distributed` success run >= 250 since candidate
- legacy hourly/daily 는 수동 smoke 로만 실행
- candidate 의 최신 `dev-soak/*` status 가 failure 가 아님
- real-device/app AI review required signal 충족

상세: [dev-pipeline.md](./dev-pipeline.md)

### rc-pr-gate

RC 의 hotfix 만 받음. `pr-gate` + 추가 mobile smoke. 머지 시 version bump commit 은 만들지 않고 `rc-deploy` 가 RC 환경을 재적용한다.

### main-pr-gate

`rc-main-cut` 이 자동 생성한 promotion PR 에 적용:
- pr-gate 재실행
- `expand-migrate-contract` 다시 검증 (RC 5일 동안 dev 가 더 나갔을 수 있음)
- RC first-parent lineage 안의 `dev-rc-cut-pass` source commit 확인

모든 check 통과 시 workflow auto-merge (rebase + ff).

### Flag staged rollout 메트릭 게이트

- error rate (Sentry, baseline +X% 이내)
- crash-free rate (Crashlytics, mobile 가장 신뢰성 높은 신호)
- latency p95 (backend 영향 받는 flag)
- business metric (5% 단계에선 trip wire 만, gate X)

상세: [life-of-flag.md](./life-of-flag.md)

## 어디에 어떤 테스트를 두나

| 테스트 성격 | 배치 위치 | 이유 |
|-------------|-----------|------|
| 결정론적, < 10분 | `dev-staging-pr-gate` | PR 사이클 안 막음 |
| flaky 또는 느림 (10분+) | dev soak monitor / real-device workflow | PR 머지 게이트의 신뢰도 보호 |
| 10분+ 이지만 nightly 전에 잡아야 하는 앱/EF 회귀 | `monitor-dev-staging-health` | dev-staging 머지는 빠르게 유지하고 최대 6시간 내 발견 |
| 외부 의존성 (실 결제 등) | dev soak + flag canary | 비용·side effect 통제 |
| 부하/성능 | scheduled monitor or staged rollout 메트릭 | 매일 무거움 |
| backend ↔ mobile 계약 호환 | `expand-migrate-contract` CI + flag canary 메트릭 | 다층 안전망 |
| 실 디바이스 다양성 | real-device workflow + `dev-soak/real-device` status | 시뮬레이터 한계 보완 |
| Mobile 회귀 (deploy 직후) | `deploy-android-*, deploy-ios-*` 의 build smoke | store upload 전 마지막 |

## 결정해야 할 것

- nightly cron 시각
- 부하 테스트 도구 (k6 / Artillery / 자체)
- mobile smoke 5개 핵심 경로 정의 + `dev-soak/real-device` status writer
- AI app soak pass/fail status writer 구현
- 카나리 cohort 정의 (내부 직원 group)
- `expand-migrate-contract` 구현 디테일 (Option C: DB schema only)

---
_Reviewed: 2026-05-19 09:47_
