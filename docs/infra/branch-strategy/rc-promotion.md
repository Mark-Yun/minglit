# RC Promotion

`rc/YYYY-Wxx` 브랜치의 lifecycle: dev 의 `dev-rc-cut-pass` commit 에서 active RC 를 하나만 cut, RC 전용 Supabase branch 생성, 5일 soak (hotfix 시 시계 리셋), true evidence 기반 `rc-main-cut-pass` 확인 후 main 으로 머지하고 RC branch 를 정리한다. RC branch 에 version bump commit 은 만들지 않고, RC artifact version 은 deploy-time metadata 로 주입한다.

## 5가지 workflow

1. **`dev-rc-cut`** — weekly cron, dev 의 latest `dev-rc-cut-pass` commit 에서 branch out
2. **`rc-pr-gate`** — dev-staging-first hotfix cherry-pick PR 머지 전 검증
3. **`rc-deploy`** — RC Supabase branch 에 migration/EF 적용 + pre-main validation
4. **`rc-main-cut-gate`** — daily cron, RC HEAD commit 의 5일 soak 와 required evidence 를 확인한 뒤 `rc-main-cut-pass` marker 부여
5. **`rc-main-cut`** — marker 가 있는 RC 를 main PR 로 promote

## `dev-rc-cut`

### 트리거 / 동작

- **cron**: 매주 X 요일 KST 10:00 (TBD)
- **manual**: `workflow_dispatch` (긴급 cut)
- **운영 계약**: 수동 실행은 `source_sha`, `rc_week`, `allow_active_rc` 입력을 지원한다. `dev-rc-cut-pass` commit 이 없으면 RC branch 를 만들지 않는다.
- 동작:
  1. **active RC marker 확인** → 있으면 skip + Slack `#release` 알림. 기본 정책은 active RC 1개만 허용
  2. 없으면 dev 의 최신 `dev-rc-cut-pass` status 부여된 commit 찾기 (GitHub API: `GET /repos/.../commits/{sha}/status`)
  3. 못 찾으면 cut 보류. failure 가 없다는 이유만으로 cut 하지 않음
  4. 찾았으면 그 commit 에서 `rc/YYYY-Wxx` branch cut
  5. Supabase branch 생성/검증은 `rc-deploy` 에 위임 (후속 PR)
  6. `promo/rc-YYYY-Wxx` tag 생성
  7. Branch protection 활성화 (direct push 금지, hotfix PR 만)
  8. active RC marker 기록 + Slack `#release` 알림 + soak 시작

### Cron 슬립 처리

- "active RC marker 있음" → skip + 다음 주 cron 까지 대기. `allow_active_rc` 는 RC abandon/비상 상황에서만 release manager 가 사용하는 override
- "dev-rc-cut-pass commit 없음 (3일+)" → cut 보류 + alert (운영자 개입 필요)

`rc/*` git branch 는 릴리즈 이력 보존 수단이 아니다. RC 종료 후 삭제할 수 있으며, 이력은 `promo/rc-*`, `promo/main-*`, GitHub Release asset 으로 보존한다.

## `rc-pr-gate`

RC 브랜치는 dev-staging 에 먼저 머지된 fix commit/snapshot 의 cherry-pick PR 만 받는다. `dev-staging-pr-gate` 와 동일 + 추가 mobile smoke (RC 가 mobile 의 source 가 될 가능성 높음).

| Check | 내용 |
|-------|------|
| (dev-staging-pr-gate 와 동일) | unit, lint, pgTAP, EF, migration, expand-migrate-contract, flag-registration, gitleaks |
| `rc-mobile-smoke` (추가) | mobile build 가능성 + 기본 navigation 동작 | 

## RC hotfix merge 후 처리

Hotfix PR 머지 직후에는 RC branch 에 version bump commit 을 추가하지 않는다.

```
1. rc-pr-gate 통과 후 hotfix PR 이 rc/YYYY-Wxx 에 merge
2. 새 commit 의 committer date 로 5일 soak clock 이 자연스럽게 reset
3. rc-deploy 가 같은 RC Supabase branch 에 migration/EF 를 재적용
4. 새 RC HEAD 기준으로 5일 soak clock 이 다시 시작
```

RC artifact version 은 `shared-version-metadata(channel=rc)` 가 latest RC HEAD 의 dev-staging snapshot build number 로 계산한다.

## `rc-deploy`

RC branch push 마다 RC 검증 환경을 구성한다. RC 는 계속 유지되는 장기 branch 가 아니라 Supabase branching 기반의 임시 검증 환경이다.

| 단계 | 동작 |
|------|------|
| branch 준비 | Supabase branch `rc-YYYY-Wxx` 생성/확인 |
| backend 적용 | RC branch 에 migration/EF apply |
| smoke | RC env smoke + backend contract 확인 |
| batch signal | `monitor-event-flow-*` 결과를 main 배포 전 검증 signal 로 사용 |

## `rc-main-cut-gate` → `rc-main-cut`

### 트리거 / 동작

- **gate cron**: daily KST 09:00 (TBD)
- **cut cron**: daily KST 09:15 (TBD, gate 직후)
- `rc-main-cut-gate` 동작:
  1. 현재 `rc/*` 가 있는지 확인 → 없으면 종료
  2. RC HEAD commit 의 `committer date` 조회
  3. `committer date` 가 5일 이전 (= 마지막 RC commit 이후 5일 soak) 인지 확인
  4. pre-main validation / event-flow signal / required `rc-soak/*` success evidence 확인
  5. `rc-soak/*` failure status 가 없는지 확인
  6. RC hotfix commit 이 dev-staging-origin fix commit/cherry-pick 인지 확인 (RC-only override 는 release-manager 기록 필요)
  7. 모두 통과하면 RC HEAD 에 `rc-main-cut-pass` 마커 부여
  8. 미충족이면 marker 를 쓰지 않고 다음날 cron 까지 대기
- `rc-main-cut` 동작:
  1. `rc-main-cut-pass` 마커가 있는 active RC 확인
  2. PR 자동 생성: `ci(rc-main-cut): promote rc/YYYY-Wxx to main` (base=main, head=rc/YYYY-Wxx)
  3. `main-pr-gate` 통과 시 workflow 가 auto-merge ([main-promotion.md](./main-promotion.md))

### Slip 자연스러움

Mark 님 직감대로 hotfix loop 으로 RC lifecycle 이 길어지는 게 일반적. 5일 시계 리셋이 자정 압박 ("PR 잘 만들기"). 평균 cycle time 은 운영하면서 metric 으로 추적.

`rc-main-cut-gate` 도 true evidence 기반이다. issue 가 없다는 사실은 pass 가 아니며, required success signal 과 run history 가 없으면 `unknown` 으로 보고 main promotion 을 만들지 않는다.

## Soak 5일 동안 무엇이 검증되나

| 검증 | 도구 |
|------|------|
| 누적 회귀 | rc 의 nightly 재실행 (선택 — RC 별도 nightly schedule TBD) |
| 내부 dogfooding | 내부 직원 cohort 가 `YY.MM.DD-rc+BUILD` 빌드 사용 |
| Real-data 이슈 | RC 전용 Supabase branch (`rc-YYYY-Wxx`) |
| 외부 의존성 동작 (실 결제, 실 메시지) | 내부 사용자가 실제로 사용해보며 검증 |

## Hotfix 경로

```
[soak 중 issue 발견]
    │
    └─▶ [fix PR 작성: feat/fix branch → dev-staging]
            │
            ├─▶ [dev-staging-pr-gate]
            ├─▶ [merge to dev-staging]
            └─▶ [same fix commit/snapshot cherry-pick PR → rc/YYYY-Wxx]
            │
            ├─▶ [rc-pr-gate]
            │
            ├─▶ [merge to rc (approved hotfix merge)]
            │
            ├─▶ [rc-deploy: RC env 재적용]
            │
            └─▶ [rc-main-cut-gate 이 다음날부터 새 committer date 인식 → 5일 다시 측정]
```

## RC Hotfix Source: dev-staging first

RC hotfix 의 source-of-truth 는 dev-staging 이다. 수정은 먼저 dev-staging 에 머지하고, active RC 에는 같은 commit/snapshot 을 cherry-pick/promote 한다. 이렇게 하면 다음 RC cut 에 같은 버그가 재출현하는지 별도 backport tracking 으로 추적하지 않아도 된다.

### `rc-hotfix-apply` workflow

```
[fix PR merged on dev-staging]
        ↓
[`rc-hotfix-apply` 수동/자동 발동]
        ↓
[bot 이 fix commit 을 active rc 에 cherry-pick 한 branch 생성]
        ↓
[PR 자동 생성: cherry-pick branch → rc/YYYY-Wxx]
        ↓
[`rc-pr-gate` 통과 시 auto-merge]
[충돌 / 테스트 실패 시: AI agent assignee, 수동 resolve]
```

### Cherry-pick 충돌

RC 는 dev 에서 cut 됐지만 active RC 가 사는 동안 dev-staging/dev 가 앞서가서 충돌 가능:
- bot 이 충돌 PR 생성 + 이슈 + AI agent assignee
- AI 가 resolve 후 push
- pr-gate 통과 시 머지

### RC-only 예외

RC 에 먼저 들어가는 `rc/hotfix/*` 는 release-manager override 가 필요한 예외다. 이 경우 PR/linked issue 에 override 사유를 남기고, 후속 dev-staging follow-up PR 을 별도로 만들어야 한다. 단, active RC 독점 정책 때문에 다음 `dev-rc-cut` 은 기존 RC 가 main/abandon 으로 종료될 때까지 막히므로, 정상 흐름에서는 dev-staging-first 만으로 충분하다.

### Mobile 의 backport 불필요

Mobile 은 release branch 없음 (main 머지 마다 `deploy-android-*, deploy-ios-*` 가 직접 build + store upload). 따라서 mobile-specific backport 흐름 없음. mobile 의 모든 hotfix 는 dev-staging → ... → rc → main 의 정상 흐름을 따라 다음 main push 시 mobile deploy workflow 들이 자동 반영.

## Supabase Branching (RC 의 backend 검증용)

**전략**: RC 마다 Supabase branch 를 생성하고, RC 종료 시 삭제한다. 단일 공유 staging branch 는 RC soak 와 dev continuous deploy 가 서로 오염될 수 있으므로 사용하지 않는다.

### Lifecycle

| 시점 | 동작 |
|------|------|
| `rc-deploy` | Supabase branch `rc-YYYY-Wxx` 생성/확인, RC SHA 기준 migration/EF deploy |
| RC soak | 내부 dogfooding 과 real-data 검증은 해당 RC branch 로만 수행 |
| hotfix merge | 같은 RC Supabase branch 에 migration/EF 재적용 |
| rc → main 완료 | prod deploy 후 RC Supabase branch 삭제 |
| RC abandon | RC Supabase branch 삭제 + active RC marker 제거 |

`dev-rc-cut-pass` 는 deploy marker 가 아니라 RC cut source marker 다. RC soak 는 `rc-YYYY-Wxx` Supabase branch 를 사용하므로 dev 의 후속 green commit 과 섞이지 않는다.

### 결정해야 할 것

- Supabase branch TTL / 비용 알림
- RC branch 의 seed data 정책

## Error-Backoff 정책

**Workflow infra 실패** (dev-rc-cut / rc-pr-gate / rc-deploy / rc-main-cut workflow 자체 실패) → **P0 이슈** + on-call.

**Soak 중 사용자 발견 회귀**:

| 심각도 | 동작 |
|--------|------|
| Minor (UI, edge case) | dev-staging fix PR → rc cherry-pick PR → rc-deploy → soak 시계 리셋 |
| Critical (crash, data loss) | flag 로 즉시 OFF (코드 release 와 분리 — life-of-flag 참고) + hotfix PR 병행 |
| Catastrophic (전체 깨짐) | RC abandon — git rc branch + Supabase branch 삭제, active marker 제거, 다음 weekly cut 새로 시작 |

## 결정해야 할 것

- weekly dev-rc-cut 요일
- rc-main-cut daily cron 시각
- RC 자체 nightly 별도 schedule 여부
- Supabase RC branch TTL / seed data 정책
- RC abandon 의 명확한 기준

## 관련

- [dev-pipeline.md](./dev-pipeline.md) — dev-rc-cut-pass status 가 dev-rc-cut 의 source
- [main-promotion.md](./main-promotion.md) — rc-main-cut + main-deploy + mobile deploy
- [test-strategy.md](./test-strategy.md) — rc-pr-gate 와 mobile smoke 위치
- [branch-flow.md](./branch-flow.md) — tag 컨벤션 + protection

---
_Reviewed: 2026-05-24 09:24_
