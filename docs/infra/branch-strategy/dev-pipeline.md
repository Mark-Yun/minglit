# Dev Pipeline

`dev` 브랜치가 trunk 역할: dev-staging 의 daily snapshot 을 받고, post-merge 로 full integration suite (`rc-gate`) 를 돌려, 통과한 commit 마다 backend/web auto-deploy. RC 는 이 status 를 보고 cut.

## 4가지 workflow

1. **`nightly-cut`** — daily cron, dev-staging tip 의 snapshot 으로 PR 생성
2. **`nightly-pr-gate`** — snapshot PR 머지 전 검증 (defensive)
3. **`rc-gate`** — dev 머지 후 자동 발동, full integration suite, 통과 시 status `rc-gate-pass` set
4. **Auto-deploy chain** — `rc-gate-pass` 시점에 `backend-auto-deploy` + `web-auto-deploy` 동시 trigger

## `nightly-cut`

### 트리거 / 동작

- **cron**: 매일 KST 02:00 (TBD)
- **manual**: `workflow_dispatch`
- 동작:
  1. 가장 최근 `v*-dev-staging` 태그 (dev-staging 의 latest coherent snapshot) 찾기
  2. PR 생성: `chore(promo): dev-staging → dev YYYY-MM-DD` (base=dev, head=dev-staging at that tag)
  3. `nightly-pr-gate` 자동 발동
  4. 통과 시 auto-merge (merge — snapshot 보존)

### 슬립 처리

- 이미 dev 가 최신 dev-staging 과 동기화돼 있으면 (= 새 commit 없음) skip
- 이전 nightly-cut 이 still in progress (드물) → 이번 cron skip + Slack 알림

## `nightly-pr-gate`

`dev-staging-pr-gate` 와 **동일한 test suite**. 환경 차이 회귀만 잡는 defensive 검증. 대부분 통과.

(상세는 [dev-staging-pipeline.md](./dev-staging-pipeline.md))

## `rc-gate` — Heavy Integration

dev 머지 후 자동 발동. 통과 = "이 commit 은 RC 가능 + backend/web prod 배포 가능".

### 무엇을 도는가

매트릭스 병렬. 하나라도 실패 = rc-gate 전체 실패.

| job | 대상 | 비고 |
|-----|------|------|
| `cuj-app-user` | `apps/app_user/patrol_test/cuj/*` | `--flavor dev --dart-define-from-file=.../dev/flutter.env` 필수 |
| `cuj-app-partner` | `apps/app_partner/patrol_test/cuj/*` | 같음 |
| `integration-backend` | `tests/backend_integration/**` | Supabase staging or ephemeral branch |
| `integration-edge-functions` | `tests/ef_integration/**` | EF 통합 시나리오 |
| `simulator-happy` | `tests/simulator/scenarios/happy/*` | cascade prob 0.85~0.95 |
| `simulator-chaos` | `tests/simulator/scenarios/chaos/*` | chaos mode, 회복 검증 |
| `test-lab-smoke` | Firebase Test Lab — 실 디바이스 4종 | 디바이스 다양성 보강 |

### 통과 시 (rc-gate-pass)

```
1. dev HEAD commit 에 GitHub commit status `rc-gate-pass` set
2. Auto-deploy chain workflow_call:
   - backend-auto-deploy (EF + migration apply)
   - web-auto-deploy (Vercel hooks 4앱)
3. (Mobile 은 deploy 없음 — main 의 monthly cut 에서 처리)
```

### 실패 시

- Status 미부여 (`rc-gate-pass` 없음 → rc-cut 이 이 commit 안 골라잡음)
- 자동 이슈 + `P1-high` 라벨 + 직전 `rc-gate-pass` 이후 머지된 PR 작성자들 assignee
- Bot auto-revert + AI fix flow (다음 섹션)

### 60분 비용 예산

전체 60분 안에. 넘으면: 매트릭스 분할, selective run, weekly 로 이동. macOS matrix 필요 시 ubuntu-latest 와 병행.

## Auto-revert + AI Fix Flow

`rc-gate` 실패 시 정상 cadence 유지를 위한 자동화:

```
[rc-gate fail on dev commit C]
        │
        ├─▶ [봇이 culprit 추정]
        │       - 휴리스틱: 실패한 test area + 그 area 변경한 PR
        │       - AI agent 분석 (rc-gate log + diff 컨텍스트)
        │       - 신뢰도 낮으면 직전 rc-gate-pass 이후 PR 들 모두 후보
        │
        ├─▶ [봇이 revert PR 자동 생성] (dev-staging 에 PR 머지)
        │       └─ 다음 nightly-cut 에서 자동으로 dev 로 promote → 다음 rc-gate
        │
        └─▶ [이슈 자동 파일링]
                  body: revert SHA + rc-gate log + 추정 원인
                  assignee: 원래 PR 작성자 (AI agent)
                        │
                        └─▶ AI 가 fix PR 작성 (revert 된 코드의 forward-fix)
                              │
                              └─▶ dev-staging-pr-gate → 정상 flow → 다음 rc-gate 검증
```

**핵심**: revert 와 fix 는 *경쟁* 아니라 *순차*. revert = stabilization (즉시 dev 회복), fix = resolution (async AI 작업).

## Error-Backoff 정책

**Workflow infra 실패** (`rc-gate` script 에러, runner 다운, deploy hook 실패 등) → **P0 이슈 자동 생성** + on-call. 아래는 *rc-gate test* 실패 escalation.

| 연속 실패 | 동작 |
|----------|------|
| 1회 | 자동 revert + 이슈 + Slack `#nightly` |
| 2회 (같은 area) | 기존 이슈 댓글 누적, assignee reminder, 영역 owner 추가 알림 |
| 3회 (같은 area) | `rc-gate-degraded` label + **rc-cut workflow 자동 차단** (다음 weekly cut PR 생성 안 함) + Slack `#release` |

**Recovery**: 다음 rc-gate green → 자동 차단 해제, 누적 이슈 verify 코멘트.

## Auto-deploy 워크플로우

### backend-auto-deploy

- Supabase EF 배포 (deno deploy)
- Migration apply (Supabase CLI)
- Sentry release marker 부여 (`v{ver}-dev` 형식)
- 실패 시: retry 1회 → 실패 시 P0 이슈 + on-call

### web-auto-deploy

- Vercel deploy hooks 4앱 (app_user, app_partner, landing_user, landing_partner)
- 현재 cron 2시간 → push-event 기반으로 교체
- 실패 시: retry 1회 → 실패 시 P0 이슈

## Artifact / 보존

- 실패한 rc-gate: 30일 (스크린샷, 로그, APK)
- 성공: 7일

## 결정해야 할 것

- nightly-cut cron 시각
- AI culprit 식별 도구 (Claude Code agent / 자체 휴리스틱)
- backoff 임계 (3회 차단이 적정한가)
- ephemeral Supabase branch (RC 마다 새로 vs 단일 공유)
- rc-gate selective run 도입 시점

## 관련

- [dev-staging-pipeline.md](./dev-staging-pipeline.md) — dev-staging 의 pr-gate + safety net
- [rc-promotion.md](./rc-promotion.md) — rc-gate-pass 가 rc-cut 의 source
- [main-promotion.md](./main-promotion.md) — auto-deploy 실패 시 rollback
- [test-strategy.md](./test-strategy.md) — rc-gate 의 단계별 위치
- [branch-flow.md](./branch-flow.md) — auto-deploy chain 그림

---
_Reviewed: 2026-05-19 09:47_
