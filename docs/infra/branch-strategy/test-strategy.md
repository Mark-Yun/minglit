# Test Strategy

4-stage 모델 (`dev-staging → dev → rc → main`) + flag staged rollout 환경에서, *어떤 테스트가 어느 단계에서 도는가* 의 단일 source. 빠른 검사 = `pr-gate` (각 단계), 무거운 검사 = `rc-gate` (dev 의 post-merge), 프로덕션 검증 = `mobile-cut` + flag staged.

## 단계별 게이트

| 단계 | 게이트 | 소요 | 실패 시 |
|------|--------|------|---------|
| dev-staging 머지 전 | `dev-staging-pr-gate` (unit · lint · analyze · pgTAP · EF test · migration check · `expand-migrate-contract` · `flag-registration` · gitleaks) | < 10분 | merge queue PR drop |
| dev 머지 전 | `nightly-pr-gate` (dev-staging-pr-gate 와 동일 — defensive) | < 10분 | nightly-cut PR drop |
| dev 머지 후 (자동) | `rc-gate` (full: CUJ · integration · e2e · simulator · Test Lab smoke) | 30-60분 | 자동 이슈 + AI fix flow. status 미부여 |
| rc 머지 전 (hotfix) | `rc-pr-gate` (pr-gate + mobile smoke) | < 15분 | hotfix PR drop |
| main 머지 전 (rc → main) | `main-pr-gate` (pr-gate + `expand-migrate-contract` 재검증 + RC HEAD 의 `rc-gate-pass` 확인) | 분 | promotion PR 보류 |
| rc → main PR | workflow auto-merge (모든 check 통과 시) | 분 | check 실패 시 PR hold + alert |
| Backend/Web auto-deploy 후 | post-deploy smoke + Sentry/Crashlytics 알람 임계 | 분 | auto-rollback ([main-promotion.md](./main-promotion.md)) |
| mobile-cut 후 | mobile-specific smoke (build + Test Lab 회귀) | 시간 | cut 차단, 직전 main commit 시도 |
| Flag canary (allowlist) | Statsig metric gates | 며칠 | flag flip OFF |
| Flag staged (5/25/100%) | Statsig one-sided sequential | 48h/72h/7일 | hold or rollback |

## Stage 별 상세

### dev-staging-pr-gate — 빠른 머지 게이트

merge queue 가 직렬 처리. 각 PR 이 rebase 후 재실행.

- `test-flutter-apps` (matrix: app_user, app_partner)
- `lint-landing-user`, `lint-landing-partner`
- `test-supabase` (pgTAP)
- `test-edge-functions` (Deno)
- `check-migration-versions`
- **`expand-migrate-contract`** (safety net — DB schema 6-month 호환)
- **`flag-registration-check`** (safety net — 새 코드 path 가 flag SDK 참조)
- `gitleaks`
- CodeRabbit 리뷰 (최대 30분 대기)

룰: 10분 넘으면 `rc-gate` 로 이동.

### nightly-pr-gate

`dev-staging-pr-gate` 와 동일한 test suite. 환경 차이로 인한 회귀만 잡는 defensive 검증. 대부분 통과.

### rc-gate — Heavy Integration

dev 머지 후 자동 발동. 통과 시 commit 에 GitHub status `rc-gate-pass` set + `backend-auto-deploy` + `web-auto-deploy` chain.

- CUJ (app_user, app_partner)
- Integration tests (backend, edge functions)
- Simulator happy/chaos 시나리오
- 풀 e2e
- Firebase Test Lab smoke (실 디바이스 다양성)

상세: [dev-pipeline.md](./dev-pipeline.md)

### rc-pr-gate

RC 의 hotfix 만 받음. `pr-gate` + 추가 mobile smoke. 머지 시 `rc-post-merge-sync` 가 `_rc-NN` bump.

### main-pr-gate

`rc-soak-check` 가 자동 생성한 promotion PR 에 적용:
- pr-gate 재실행
- `expand-migrate-contract` 다시 검증 (RC 5일 동안 dev 가 더 나갔을 수 있음)
- RC HEAD 의 `rc-gate-pass` status 확인 (마지막 hotfix 이 rc-gate 통과했는지)

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
| flaky 또는 느림 (10분+) | `rc-gate` | merge queue 신뢰도 보호 |
| 외부 의존성 (실 결제 등) | `rc-gate` + flag canary | 비용·side effect 통제 |
| 부하/성능 | `rc-gate` (주 1회) or staged rollout 메트릭 | 매일 무거움 |
| backend ↔ mobile 계약 호환 | `expand-migrate-contract` CI + flag canary 메트릭 | 다층 안전망 |
| 실 디바이스 다양성 | `rc-gate` 의 Firebase Test Lab | 시뮬레이터 한계 보완 |
| Mobile 회귀 (cut 직후) | `mobile-cut` 의 mobile-specific smoke | app store 업로드 전 마지막 |

## 결정해야 할 것

- nightly cron 시각
- 부하 테스트 도구 (k6 / Artillery / 자체)
- mobile smoke 5개 핵심 경로 정의
- 카나리 cohort 정의 (내부 직원 group)
- `expand-migrate-contract` 구현 디테일 (Option C: DB schema only)

---
_Reviewed: 2026-05-19 09:47_
