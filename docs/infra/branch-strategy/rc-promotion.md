# RC Promotion

`rc/YYYY-Wxx` 브랜치의 lifecycle: weekly cut from dev 의 `rc-gate-pass` commit, 5일 soak (hotfix 시 시계 리셋), soak 통과 시 main 으로 머지.

## 4가지 workflow

1. **`rc-cut`** — weekly cron, dev 의 latest `rc-gate-pass` commit 에서 branch out
2. **`rc-pr-gate`** — hotfix PR 머지 전 검증
3. **`rc-post-merge-sync`** — hotfix 머지 직후 (`_rc-NN` bump)
4. **`rc-soak-check`** — daily cron, RC HEAD commit 의 committer date 가 5일 이전이면 rc → main PR 자동 생성

## `rc-cut`

### 트리거 / 동작

- **cron**: 매주 X 요일 KST 10:00 (TBD)
- **manual**: `workflow_dispatch` (긴급 cut)
- 동작:
  1. **현재 `rc/*` 살아있는지 확인** → 있으면 skip + Slack `#release` 알림 (이전 RC 가 hotfix 로 길어지는 중)
  2. 없으면 dev 의 최신 `rc-gate-pass` status 부여된 commit 찾기 (GitHub API: `GET /repos/.../commits/{sha}/status`)
  3. 못 찾으면 (3일+ green 없음) → alert + cut 보류
  4. 찾았으면 그 commit 에서 `rc/YYYY-Wxx` branch cut
  5. `bump-version.sh {ver}-rc-01` 실행 → tag `v{ver}-rc-01` + `promo/rc-YYYY-Wxx`
  6. Branch protection 활성화 (direct push 금지, cherry-pick PR 만)
  7. Slack `#release` 알림 + soak 시작

### Cron 슬립 처리

- "현재 `rc/*` 살아있음" → skip + 다음 주 cron 까지 대기
- "rc-gate-pass commit 없음 (3일+)" → cut 보류 + alert (운영자 개입 필요)

## `rc-pr-gate`

RC 브랜치는 hotfix PR 만 받음. `dev-staging-pr-gate` 와 동일 + 추가 mobile smoke (RC 가 mobile 의 source 가 될 가능성 높음).

| Check | 내용 |
|-------|------|
| (dev-staging-pr-gate 와 동일) | unit, lint, pgTAP, EF, migration, expand-migrate-contract, flag-registration, gitleaks |
| `rc-mobile-smoke` (추가) | mobile build 가능성 + 기본 navigation 동작 | 

## `rc-post-merge-sync`

Hotfix PR 머지 직후 자동:

```
1. bump-version.sh {PR번호}-rc-NN  (NN = 현재 RC 의 hotfix 카운트 + 1)
2. git commit -m "chore: bump RC version [skip ci]"
3. git tag v{ver}-rc-NN
4. git push
```

**Soak 시계 자동 리셋** — 새 commit 의 committer date 가 최신이므로 `rc-soak-check` 가 자연스럽게 카운트 다시 시작.

### Hotfix 카운트 결정

`bump-version.sh` 가 현재 RC 의 가장 최근 `v*-rc-NN` 태그 찾아 N + 1 로 bump. 첫 cut 이 `_rc-01`, 첫 hotfix 가 `_rc-02`.

## `rc-soak-check`

### 트리거 / 동작

- **cron**: daily KST 09:00 (TBD)
- 동작:
  1. 현재 `rc/*` 가 있는지 확인 → 없으면 종료
  2. RC HEAD commit 의 `committer date` 조회
  3. `committer date` 가 5일 이전 (= 5일 동안 새 commit 없음) 이면:
     - PR 자동 생성: `release(main): RC YYYY-Wxx → main` (base=main, head=rc/YYYY-Wxx)
     - PR 에 `rc-soak-passed` 마커 부여
     - `main-pr-gate` 통과 시 workflow 가 auto-merge ([main-promotion.md](./main-promotion.md))
  4. 5일 이전 아니면 → 다음날 cron 까지 대기

### Slip 자연스러움

Mark 님 직감대로 hotfix loop 으로 RC lifecycle 이 길어지는 게 일반적. 5일 시계 리셋이 자정 압박 ("PR 잘 만들기"). 평균 cycle time 은 운영하면서 metric 으로 추적.

## Soak 5일 동안 무엇이 검증되나

| 검증 | 도구 |
|------|------|
| 누적 회귀 | rc 의 nightly 재실행 (선택 — RC 별도 nightly schedule TBD) |
| 내부 dogfooding | 내부 직원 cohort 가 `_rc-NN` 빌드 사용 |
| Real-data 이슈 | rc 의 supabase staging branch (단일 공유 branch, 5일 후 reset) |
| 외부 의존성 동작 (실 결제, 실 메시지) | 내부 사용자가 실제로 사용해보며 검증 |

## Hotfix 경로

```
[soak 중 issue 발견]
    │
    └─▶ [hotfix PR 작성: feat/fix branch → rc/YYYY-Wxx]
            │
            ├─▶ [rc-pr-gate]
            │
            ├─▶ [merge to rc (rebase)]
            │
            ├─▶ [rc-post-merge-sync: _rc-NN bump]
            │
            └─▶ [rc-soak-check 가 다음날부터 새 committer date 인식 → 5일 다시 측정]
```

## Hotfix Backport to dev-staging

RC 의 hotfix 는 RC 에 머지 후 **반드시 dev-staging 으로 backport**. 안 하면 다음 RC cut 에 같은 버그 재출현.

### `rc-hotfix-backport` workflow

```
[hotfix PR merged on rc/YYYY-Wxx]
        ↓
[`rc-hotfix-backport` 자동 발동]
        ↓
[bot 이 cherry-pick 으로 backport-branch 생성 (base: dev-staging)]
        ↓
[PR 자동 생성: backport-branch → dev-staging]
        ↓
[`dev-staging-pr-gate` 통과 시 auto-merge]
[충돌 / 테스트 실패 시: AI agent assignee, 수동 resolve]
```

### Backport 충돌

RC 는 dev-staging 에서 cut 됐지만 RC 가 사는 동안 dev-staging 이 앞서가서 충돌 가능:
- bot 이 충돌 PR 생성 + 이슈 + AI agent assignee
- AI 가 resolve 후 push
- pr-gate 통과 시 머지

### Mobile 의 backport 불필요

Mobile 은 release branch 없음 (main 머지 마다 `deploy-android-*, deploy-ios-*` 가 직접 build + store upload). 따라서 mobile-specific backport 흐름 없음. mobile 의 모든 hotfix 는 dev-staging → ... → rc → main 의 정상 흐름을 따라 다음 main push 시 mobile deploy workflow 들이 자동 반영.

## Supabase Staging Branch (RC 의 backend 검증용)

**전략**: 단일 영구 supabase staging branch 를 모든 RC 가 공유 (RC merge to main 시점에 reset).

- 비용 절감 (RC 마다 새 branch 안 만듬)
- 복잡도 낮음 (sync 디테일 단순)
- expand-migrate-contract CI 가 PR 시점에 destructive 검증 → 5일 소크 시점 추가 보호

이전: RC 마다 ephemeral branch — runtime 가격 누적, 복잡.
지금: 1 branch 영구 운영. RC merge to main → DB reset → 다음 RC 가 깨끗한 상태에서 시작.

### 결정해야 할 것

- staging branch reset 시점 정확화 (main 머지 직후 / 다음 rc-cut 직전)
- staging branch 의 seed data 정책

## Error-Backoff 정책

**Workflow infra 실패** (rc-cut / rc-pr-gate / rc-soak-check workflow 자체 실패) → **P0 이슈** + on-call.

**Soak 중 사용자 발견 회귀**:

| 심각도 | 동작 |
|--------|------|
| Minor (UI, edge case) | hotfix PR → rc-post-merge-sync → soak 시계 리셋 |
| Critical (crash, data loss) | flag 로 즉시 OFF (코드 release 와 분리 — life-of-flag 참고) + hotfix PR 병행 |
| Catastrophic (전체 깨짐) | RC abandon — branch 삭제, 다음 weekly cut 새로 시작 (작업 손실) |

## 결정해야 할 것

- weekly rc-cut 요일
- rc-soak-check daily cron 시각
- RC 자체 nightly 별도 schedule 여부
- staging supabase branch reset 정책
- RC abandon 의 명확한 기준

## 관련

- [dev-pipeline.md](./dev-pipeline.md) — rc-gate-pass status 가 rc-cut 의 source
- [main-promotion.md](./main-promotion.md) — rc → main 머지 + deploy-android-*, deploy-ios-*
- [test-strategy.md](./test-strategy.md) — rc-pr-gate 와 mobile smoke 위치
- [branch-flow.md](./branch-flow.md) — tag 컨벤션 + protection

---
_Reviewed: 2026-05-19 09:47_
