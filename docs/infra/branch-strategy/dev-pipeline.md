# Dev Pipeline

`dev` 브랜치가 integration-health trunk 역할: dev-staging 의 daily snapshot 을 받고, 새 dev commit 마다 health/MDS visual signal 을 기록한다. Flutter CUJ 는 web-mvp pivot 으로 동결되어 수동 block lever 로만 남는다. `dev-rc-cut-gate` 는 commit status 와 dev cron install signal 을 평가해 `dev-rc-cut-pass` 를 쓰고, RC 는 그 status 를 보고 cut 한다. 이벤트 플로우 시뮬레이터는 dev Supabase pg_cron 으로 계속 돌며, backend prod deploy 는 main 머지 후 `main-deploy` 에서 수행한다.

## 주요 workflow

1. **`dev-staging-dev-cut`** — daily cron, dev-staging tip 을 직접 bump/tag 한 뒤 그 snapshot 으로 PR 생성
2. **`dev-pr-gate`** — snapshot PR 머지 전 검증 (defensive)
3. **`monitor-dev-cuj`** (동결 — web-mvp pivot) — disable 됨. `dev-soak/cuj-*` 는 `set-dev-soak-status` 수동 블락 레버로만 유지
4. **`sync-mds-render-snapshot`** — dev push 마다 MDS emulator render PNG 를 `artifacts/mds-render` 에 SHA-bound 저장하고 `mds-render/snapshot` status 기록
5. **AI visual review** — `artifacts/mds-render` 의 dev SHA snapshot 을 MDS spec 과 비교하고 `dev-soak/app-ai-review` 기록
6. **`dev-rc-cut-gate`** — cut 직전 evaluator. dev health status + cron install run 확인 후 `dev-rc-cut-pass` set
7. **`dev-deploy` / cron install** — dev 환경 deploy/smoke 가 필요할 때 수행. 이벤트 플로우 시뮬레이터는 dev pg_cron 으로 별도 운영

## `dev-staging-dev-cut`

### 트리거 / 동작

- **cron**: 매일 KST 02:00 (TBD)
- **manual**: `workflow_dispatch`
- 동작:
  1. open `cut/dev-staging-dev/*` PR 이 있으면 skip
  2. `tag_name` 입력이 있으면 해당 `v*-dev-staging` tag 를 promote 대상으로 사용
  3. 입력이 없으면 현재 `origin/dev-staging` HEAD 에 `YY.MM.DD-dev-staging+YYMMDDNN` version bump commit 을 만들고 release bot 이 protected `dev-staging` 에 fast-forward push
  4. 같은 commit 에 `vYY.MM.DD+YYMMDDNN-dev-staging` tag 생성
  5. PR 생성: `ci(dev-staging-dev-cut): promote v26.06.01+26060101-dev-staging to dev` (base=dev, head=`cut/dev-staging-dev/YYYY-MM-DD-{sha8}` at that tag)
  6. `dev-pr-gate` 자동 발동
  7. 통과 시 auto-merge (merge commit — dev-staging snapshot ancestry 보존)

### 슬립 처리

- 이미 dev 가 최신 dev-staging 과 동기화돼 있으면 (= 새 commit 없음) skip
- 이전 dev-staging-dev-cut 이 still in progress (드물) → 이번 cron skip + Slack 알림
- partial run 으로 dev-staging HEAD 에 이미 `v*-dev-staging` tag 가 있으면 새 bump 를 만들지 않고 그 tag 를 재사용

## `dev-pr-gate`

`dev-staging-pr-gate` 와 **동일한 test suite**. 환경 차이 회귀만 잡는 defensive 검증. 대부분 통과.

(상세는 [dev-staging-pipeline.md](./dev-staging-pipeline.md))

## `dev-rc-cut-gate` — Health Evaluator

cut 직전 schedule/manual 로 실행된다. 통과 = "이 dev HEAD commit 은 RC cut source 로 사용할 수 있음".

> **정책 변경**: `dev-rc-cut-gate` 는 heavy test runner 가 아니라 evaluator 다. 테스트/모니터는 별도 workflow 또는 AI agent 가 돌고, 실패 즉시 commit status 를 남긴다. Dev 단계의 24h soak 는 폐기하고, RC 단계에서만 5일 soak 를 운영한다.

### Source of truth

GitHub Issue 는 source-of-truth 가 아니다. Gate 판정은 commit status context 와 GitHub Actions run history 를 사용한다.

`dev-rc-cut-gate` 는 **true evidence** 만 pass 로 본다. required success status/run history 가 없으면 상태는 `unknown` 이며, failure status 나 blocker issue 가 없더라도 RC cut source 로 선택하지 않는다.

| Context | failure 작성자 | success 작성자 |
|---------|---------------|----------------|
| `dev-soak/backend-simulator` | `event-flow-simulator` reporter 또는 `deploy-dev-event-flow-cron` 실패 path | `dev-rc-cut-gate` |
| `dev-soak/cuj-user` | `set-dev-soak-status` (manual; `monitor-dev-cuj` 동결) | manual |
| `dev-soak/cuj-partner` | `set-dev-soak-status` (manual; `monitor-dev-cuj` 동결) | manual |
| `mds-render/snapshot` | `sync-mds-render-snapshot` | `sync-mds-render-snapshot` |
| `dev-soak/real-device` | real-device/Test Lab workflow 또는 AI agent | `dev-rc-cut-gate` |
| `dev-soak/app-ai-review` | AI agent | `dev-rc-cut-gate` |
| `dev-rc-cut-pass` | 없음 | `dev-rc-cut-gate` |

`dev-soak/*` 는 legacy context prefix 다. 정책상 dev soak 는 없지만 existing consumer 호환을 위해 status prefix 를 유지한다. 상세 승격 계약은 [promotion-contract.md](./promotion-contract.md), status model 은 [dev-soak-status-model.md](./dev-soak-status-model.md) 를 따른다.

### 무엇을 확인하는가

`dev-rc-cut-gate` 는 latest `origin/dev` HEAD 만 평가한다. dev 에 새 commit 이 들어오면 candidate 는 새 HEAD 로 교체된다.

| 검증 | 조건 |
|------|------|
| Event-flow distributed simulator | candidate SHA 에서 `deploy-dev-event-flow-cron` success >= 1 + `dev-soak/backend-simulator` failure 없음 |
| CUJ (동결 — web-mvp pivot) | run 요구 제거. `dev-soak/cuj-user` / `dev-soak/cuj-partner` failure 없음만 확인 (수동 블락 레버) |
| MDS render snapshot | candidate SHA 에서 `mds-render/snapshot=success` + `artifacts/mds-render/snapshots/dev/<sha>/` 저장 완료 |
| Legacy hourly/daily simulator | 수동 smoke 전용. RC cut gate 조건에서 제외 |
| Real device | candidate 기준 required real-device signal success >= 1 (workflow TBD) |
| App AI review | AI agent 가 candidate 기준 `artifacts/mds-render` snapshot 을 비교하고 `dev-soak/app-ai-review` pass signal 제공 |
| Failure status | `dev-soak/*` context 의 최신 state 가 `failure` 가 아니어야 함 |
| Positive evidence | required run history 와 required signal success 가 모두 존재해야 함. 미존재는 pass 가 아니라 unknown |

### 통과 시 (dev-rc-cut-pass)

```
1. dev HEAD commit 에 GitHub commit status `dev-rc-cut-pass` set
2. required `dev-soak/*` status 도 evaluator 또는 writer 가 success 로 확정
3. `dev-rc-cut` 이 `dev-rc-cut-pass` 를 source-of-truth 로 사용
4. Mobile + backend prod 은 main 머지 후 `main-deploy` 에서 처리
```

> **사용자 서버 영향 X** — `dev-rc-cut-pass` 는 prod deploy 가 아니라 RC 후보 marker 다. prod 는 main 머지에서만 배포한다.

### 실패 시

Snapshot 모델 — **auto-revert 없음**. dev 가 broken 상태로 잠시 머묾, AI agent 가 fix PR 을 normal flow 로 처리.

- Status 미부여 (`dev-rc-cut-pass` 없음 → dev-rc-cut 이 이 commit 안 골라잡음)
- 실패를 발견한 monitor/AI agent 가 `dev-soak/*` failure status 를 즉시 작성
- MDS render 저장 실패는 `mds-render/snapshot=failure`, visual blocker 는 `dev-soak/app-ai-review=failure`
- `shared-notify` 가 release-blocker issue 를 생성/갱신하되, issue 상태는 gate 판정 source-of-truth 로 쓰지 않음
- 자동 이슈 + `P1-high` 라벨 + 직전 `dev-rc-cut-pass` 이후 머지된 PR 작성자들 assignee (AI agent 포함)
- AI agent 가 fix PR 을 dev-staging 으로 작성 → dev-staging-pr-gate → 다음 dev-staging-dev-cut → 다음 dev-rc-cut-gate 가 검증
- dev 는 *broken integration 상태* 지만 `pr-gate-core` 가 compile/unit 잡아주니 다른 PR 진입 자체는 OK

### 60분 비용 예산

전체 60분 안에. 넘으면: 매트릭스 분할, selective run, weekly 로 이동. macOS matrix 필요 시 ubuntu-latest 와 병행.

## Error-Backoff 정책

**Workflow infra 실패** (`dev-rc-cut-gate` script 에러, runner 다운 등) → **P0 이슈 자동 생성** + on-call. 아래는 *dev-rc-cut-gate test* 실패 escalation.

| 연속 실패 | 동작 |
|----------|------|
| 1회 | 자동 이슈 + Slack `#nightly` + AI agent assignee |
| 2회 (같은 area) | 기존 이슈 댓글 누적, assignee reminder, 영역 owner 추가 알림 |
| 3회 (같은 area) | `dev-rc-cut-gate-degraded` label + **dev-rc-cut workflow 자동 차단** (다음 weekly cut PR 생성 안 함) + Slack `#release` |

**Recovery**: 다음 dev-rc-cut-gate green → 자동 차단 해제, 누적 이슈 verify 코멘트.

## Dev Validation / Monitor

### `dev-deploy`

`dev-deploy` 는 dev 환경 deploy/smoke 가 필요할 때의 branch-level entrypoint 다. 현재 release policy 에서는 backend prod deploy 를 여기서 하지 않는다.

### `monitor-event-flow-*`

- 이벤트 플로우 시뮬레이터 batch. 대상은 dev Supabase pg_cron `dev-event-flow-simulator` 5분 주기 small tick
- 시간은 고정 5분, 랜덤은 actor/user/partner/event sampling 에 적용한다
- `seed.dev.sql` 은 계정/파트너 base 만 담당하고 party/event/ticket 은 EF 경유로 만든다
- 유저 신청 대상은 DB prefix 필터가 아니라 `user-event-feed` 결과에서 선택한다
- `monitor-event-flow-distributed` / hourly / daily 는 legacy manual smoke
- release promotion 과 독립적으로 계속 돈다
- RC 에서는 main 배포 전 pre-main validation signal 로 사용한다

### `sync-mds-render-snapshot`

- `push` to `dev` 의 promoted SHA 를 기준으로 MDS emulator render 를 실행한다.
- PNG 는 source branch 에 커밋하지 않고 `artifacts/mds-render` branch 의 `snapshots/dev/<dev-sha>/` 에만 커밋한다.
- 해당 dev SHA 에 `mds-render/snapshot` status 를 쓴다. `target_url` 은 artifact branch/path 또는 workflow summary 를 가리킨다.
- PNG diff 가 있으면 `sync-mds-render-snapshot` 이 `mds_render_snapshot_archived` repository dispatch 를 보내고, `triage-mds-render-snapshot-diff` 가 review issue 를 만든다.
- AI visual review agent 는 이 branch 를 fetch 해 MDS spec PNG 와 비교한다. 확정 blocker 는 finding 당 별도 fix issue 로 만들고 `dev-soak/app-ai-review=failure` 를 기록한다. blocker 가 없으면 `dev-soak/app-ai-review=success` 를 기록한다.
- 발견된 visual blocker/fix 는 모두 `dev-staging` PR 로 처리한다. `dev` 에 PNG/fix commit 을 직접 만들지 않는다.

## Artifact / 보존

- 실패한 monitor/soak workflow: 30일 (스크린샷, 로그, APK)
- 성공한 `dev-rc-cut-gate` evaluator run: 7일
- MDS render PNG: `artifacts/mds-render` branch 에 SHA-bound path 로 영구 보존. Actions artifact 는 디버깅 보조용

## 결정해야 할 것

- dev-staging-dev-cut cron 시각
- backoff 임계 (3회 차단이 적정한가)
- real-device/app AI review status writer 구현 방식
- `sync-mds-render-snapshot` branch push/retry 구현 방식
- `shared-notify` 의 release signal metadata/log tail 확장
- Supabase RC branch TTL / seed data 정책

## 관련

- [dev-staging-pipeline.md](./dev-staging-pipeline.md) — dev-staging 의 pr-gate + safety net
- [rc-promotion.md](./rc-promotion.md) — dev-rc-cut-pass 가 dev-rc-cut 의 source
- [main-promotion.md](./main-promotion.md) — main-deploy 와 prod deploy failure handling
- [test-strategy.md](./test-strategy.md) — dev-rc-cut-gate 의 단계별 위치
- [branch-flow.md](./branch-flow.md) — workflow chain 그림

---
_Reviewed: 2026-06-04 22:11_
