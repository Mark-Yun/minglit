# Error Detection

각 단계에서 에러를 어떻게 *detect* 하고, detection → action 까지 얼마나 빨리 가는지. *어떤 테스트* 는 [test-strategy.md](./test-strategy.md), *detect 후 무엇* 은 각 promotion 의 error-backoff 섹션, **이 문서는 detection layer**.

## Layered Detection

| Stage | Detection 도구 | 잡는 에러 | Latency |
|-------|----------------|----------|---------|
| 개발자 로컬 | LSP, analyze, unit | 컴파일/타입/단위 | 초~분 |
| dev-staging PR gate | `dev-staging-pr-gate` (unit, lint, pgTAP, EF, migration, `expand-migrate-contract`, `flag-registration`, gitleaks) | PR 회귀, 보안, migration 충돌, flag 미등록, contract 위반 | < 10분 |
| dev-staging-dev-cut PR | `dev-pr-gate` (defensive) | 환경 차이 회귀 | < 10분 |
| dev health | `deploy-dev-event-flow-cron`, `monitor-dev-cuj`, real-device workflow, AI app review status writer via `set-dev-soak-status` | backend simulator, CUJ, 외부 의존, 디바이스, UX/blocker | 즉시~분 |
| RC cut 직전 | `dev-rc-cut-gate` evaluator | required dev health evidence 미충족, `dev-soak/*` failure status, monitor 미실행 | 분 |
| Backend/Web deploy validation | post-deploy smoke, Sentry release marker | deploy infra 회귀 | 분 |
| rc soak (5일) | rc 의 nightly 재실행 + 내부 dogfooding | 누적 회귀, real-data 이슈 | 일 단위 |
| main 머지 후 (auto-deploy) | smoke + Sentry/Crashlytics 알람 임계 | prod 회귀 | 분 |
| deploy-android-*, deploy-ios-* 후 | mobile build smoke + Crashlytics dSYM/mapping 등록 | mobile build 회귀, sign 실패 | 시간 |
| flag canary (allowlist) | Statsig metric (error rate, crash-free) | 실사용자 회귀 (canary) | 분~시간 |
| flag staged 5/25/100% | 위 + cohort 비교 | 새 cohort 회귀 | 분~시간 |
| 100% 운영 | uptime, on-call | infra-level, 장기 회귀 | 분~일 |

## 도구 별 책임

### Sentry
- Backend / mobile / web 의 unhandled exception, error log
- Release tagging (`v{ver}` 마커) → "이 commit 부터 새 에러" 추적
- Alert: error rate spike, new issue

### Firebase Crashlytics
- Mobile crash (native crash, isolate crash)
- Crash-free rate — **mobile 가장 신뢰성 높은 신호**
- 상세: [../firebase/BLUEDOC.md](../firebase/BLUEDOC.md)

### Firebase Test Lab
- 실 디바이스 farm 에서 CUJ/smoke
- 실패 즉시 `dev-soak/real-device` commit status 를 failure 로 기록
- 상세: [../firebase/BLUEDOC.md](../firebase/BLUEDOC.md)

### Statsig
- Flag staged rollout 메트릭 게이트 (one-sided sequential testing)
- A/B holdout 분석
- 상세: [../statsig/BLUEDOC.md](../statsig/BLUEDOC.md)

### Axiom / Supabase logs
- Backend (EF) 로그 수집
- 참고: `docs/operations/edge-functions.md`

### GitHub Actions
- pr-gate / monitor / promotion workflow 의 자동 이슈 생성
- `shared-notify` 는 release blocker incident 를 issue 로 남기고, gate 판정용 commit status 를 기록
- **workflow infra 실패 → P0**, test/health/soak 실패 → P1-high

## Detection → Action 책임

| Detection 신호 | 누가 받음 | 어디서 | Action |
|---------------|----------|--------|--------|
| pr-gate 실패 (어느 단계든) | PR 작성자 | GitHub PR | 본인 fix → re-push → auto-merge 재대기 |
| `dev-soak/*` failure status | 직전 dev-rc-cut-pass 이후 머지된 PR 작성자들 + AI agent | commit status + GitHub issue + Slack `#nightly` | AI agent fix PR via dev-staging — dev keeps moving ([dev-pipeline.md](./dev-pipeline.md)) |
| `dev-rc-cut-gate` evaluator 미충족 | release manager / AI agent | GitHub Actions run summary | RC cut 보류. failure status 또는 monitor run history 부족 원인 확인 |
| Backend/web deploy validation 실패 | on-call | Slack `#release` | retry → P0 이슈, 해당 promotion/deploy 진행 차단 |
| Backend/web/mobile prod deploy 실패 (main 머지) | on-call | Slack `#release` | retry → rollback ([main-promotion.md](./main-promotion.md) error-backoff) |
| rc soak 중 회귀 | RC owner | Slack `#release` | hotfix PR → rc |
| deploy-android-*, deploy-ios-* 실패 | mobile 팀 | GitHub issue + Slack | retry + auto-issue ([main-promotion.md](./main-promotion.md) error-backoff) |
| Sentry alert (error spike) | 영역 owner | Sentry → Slack | 영역 별 on-call 판단 |
| Crashlytics velocity alert | mobile 팀 | Firebase → Slack | flag flip OFF 우선 |
| Statsig metric gate | flag owner | Statsig dashboard | flag rollback ([life-of-flag.md](./life-of-flag.md)) |
| Workflow infra 실패 (P0) | on-call | GitHub issue + PagerDuty | 즉시 |

## Detection Gap 방지

- 신규 EF / 새 화면: Sentry release tag + Crashlytics dSYM 등록 필수
- 신규 flag: 메트릭 게이트 정의 강제 (Statsig 콘솔 metric 미연결 = warning)
- 새 코드 path: flag SDK reference 강제 (`flag-registration` CI)
- alert silence: owner + 이유 + 재활성 일자 명시

## 결정해야 할 것

- alert 채널 통합 vs 분리 (Slack 구조)
- on-call rotation 정의
- alert 임계치 (error rate baseline 측정)
- Crashlytics + Sentry 양쪽 vs 한쪽 통일

## 관련

- [test-strategy.md](./test-strategy.md) — 어떤 테스트
- [dev-pipeline.md](./dev-pipeline.md) — dev-rc-cut-gate detection → backoff
- [main-promotion.md](./main-promotion.md) — deploy detection → rollback
- [life-of-flag.md](./life-of-flag.md) — flag 메트릭 → flip
- [../firebase/BLUEDOC.md](../firebase/BLUEDOC.md), [../statsig/BLUEDOC.md](../statsig/BLUEDOC.md)

---
_Reviewed: 2026-05-19 09:47_
