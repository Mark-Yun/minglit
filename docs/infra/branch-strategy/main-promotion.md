# Main Promotion

`rc/YYYY-Wxx` 의 soak 통과 시 `main` 으로 머지, 그리고 main 에서 월 1회 `mobile-cut`. Backend/web 의 auto-deploy 는 dev 의 rc-gate-pass 에서 이미 일어남 ([dev-pipeline.md](./dev-pipeline.md)) — main 은 **mobile-stable snapshot** 역할.

## 두 가지 이벤트

1. **rc → main weekly 머지** — `rc-soak-check` 가 자동 PR 생성 + 모든 check 통과 시 workflow auto-merge
2. **mobile-cut** — 월 1회 main 에서 `release/mobile-YYYY-MM` branch cut

## `main-pr-gate`

`rc-soak-check` 가 자동 생성한 promotion PR 에 적용:

| Check | 내용 |
|-------|------|
| `pr-gate` 재실행 | dev-staging-pr-gate 와 동일 — defensive 검증 |
| `expand-migrate-contract` (재검증) | RC 5일 동안 dev 가 더 나갔을 수 있음. 재확인 |
| RC HEAD 의 `rc-gate-pass` status 확인 | 마지막 hotfix 이 rc-gate 통과했는지 |
| `rc-soak-passed` 자동 마커 | rc-soak-check 가 5일 무커밋 확인 후 부여 |

**모든 check 통과 시 workflow 가 auto-merge** (rebase + fast-forward). 어느 하나라도 실패 시 PR hold + Slack 알림 → human 개입 (edge case 만).

## `main-post-merge-promote`

auto-merge 직후 자동:

```
1. bump-version.sh {ver}  (suffix 제거 — main 은 final version)
2. git commit -m "chore: bump version to v{ver} [skip ci]"
3. git tag v{ver}
4. git tag promo/main-YYYY-Wxx
5. git push (tags + commit)
6. Sentry release marker 부여 (v{ver})
```

**Backend/web deploy 는 main 에서 하지 않음** — dev 의 rc-gate-pass 에서 이미 prod 반영됨. main 은 mobile 의 stable snapshot.

## `mobile-cut` (월 1회)

### 트리거 / 동작

- **cron**: 매월 X 일 KST 09:00 (TBD)
- **manual**: `workflow_dispatch` (긴급 mobile release)
- 동작:
  1. 그 시점 main HEAD 에서 `release/mobile-YYYY-MM` 브랜치 cut
  2. Branch protection 활성화 (direct push 금지, cherry-pick PR 만)
  3. mobile-specific smoke (build + Test Lab 회귀)
  4. **`min-version` default 자동 bump** (Safety Net 1 — 아래)
  5. 안내 issue 생성 (build/upload assignee)

### Release branch lifecycle

- cut 후 ~수일: build, internal QA, app store 업로드 (TestFlight, Internal Track)
- store 리뷰 ~수일: 필요 시 main 에서 cherry-pick PR (**자동화 도구 필수** — Runway/Xray/자체)
- store 출시 후: 다음 cut 까지 cherry-pick 핫픽스만
- 다음 month cut 시 archive 결정 (보존 vs 삭제 — TBD)

## Safety Net 1: Version Kill Switch (Soft + Hard Tier)

**정책**: 6개월 backward compat (마지막 6개 mobile release 지원). 분기별 retrospective 에서 update rate 데이터 보고 조정.

**Source of truth**: Firebase RC parameter (client + server 양쪽이 동일 source 에서 fetch).

### 두 Tier

| Tier | 메커니즘 | 사용 case |
|------|----------|----------|
| **2a. Soft kill** | client 가 `min_version_soft` (RC) + *app store 의 새 버전 가용성* 양쪽 확인 후 force-update screen | 빠른 update 유도. store rollout 중이라 일부만 새 버전 받을 수 있을 때 안전 (못 받는 사용자는 그대로 사용) |
| **2b. Hard kill** | EF middleware 가 `kill_list_hard` (RC) + `X-App-Version` header 비교 → HTTP 426 reject | catastrophic (데이터 유출, 결제 사고, 보안). 매우 드묾 |

### Tier 2a: Soft Kill 흐름

```
[client cold start]
        ↓
[Firebase RC fetch: min_version_soft]
        ↓
[내 version < min_version_soft?]
        │
        ├─ no → 정상 사용
        │
        └─ yes → [app store check (Play In-App Update / iOS StoreKit) → 새 버전 사용 가능?]
                        │
                        ├─ yes → force-update screen + 앱스토어 deep-link
                        │
                        └─ no → 정상 사용 (UX 사고 방지)
```

`min_version_soft` default = 6개월 전 mobile release version. `mobile-cut` 이 매월 자동 bump.

### Tier 2b: Hard Kill 흐름 (EF middleware)

```
[incoming request to any EF]
        ↓
[Firebase Admin SDK 로 RC fetch (캐시 5분)]
        ↓
[request.headers['X-App-Version'] ∈ kill_list_hard?]
        │
        ├─ yes → HTTP 426 Upgrade Required + update 안내
        │
        └─ no → 정상 처리 (다음 middleware)
```

`kill_list_hard` default = `[]` (안전 상태).

### Auto-bump (PR label 컨벤션)

| PR Label | Tier | `main-post-merge-promote` 동작 |
|----------|------|--------------------------------|
| (없음) | - | 변경 없음 (mobile-cut 의 monthly soft auto-bump 만) |
| `force-update` | 2a | RC `min_version_soft` 즉시 bump to 이 PR 의 `v{ver}` |
| `force-update-hard` | 2b | RC `kill_list_hard` 에 현 store-live version 추가 + Slack `#release` + on-call 호출 |

**Single source of truth = Firebase RC**. Client cold start fetch, Server EF Admin SDK fetch + 5분 캐시. RC 콘솔이 운영 dashboard.

### 결정해야 할 것

- App store check API 선택 (Play In-App Update / iOS StoreKit 직접 query)
- EF middleware 의 RC cache TTL (5분 vs 1분)
- `force-update-hard` label 부여 권한 (release manager / on-call)
- Firebase App Check 도입 여부 (별개 — 인증 layer, 버전 kill 과 무관, 보안 강화 후속 PR)

**현재 상태**: TODO. EF middleware + mobile dual check + RC parameter 셋업 + Firebase Admin SDK 인증.

## Safety Net 2: Expand-Migrate-Contract (재검증)

`main-pr-gate` 에서도 `expand-migrate-contract` CI 재실행 (RC 5일 사이 dev 가 더 나갔을 수 있음). 정책 + 구현 상세는 [dev-staging-pipeline.md](./dev-staging-pipeline.md) 참고.

**Policy 요약**:
- N = 6 mobile releases (= 6개월)
- Option C: DB schema 만 검증 (API contract test 는 TBD)
- Destructive op (DROP COLUMN/TABLE, ALTER TYPE) 탐지 + bypass label

## Cherry-pick 자동화 도구

Squarespace 데이터: 자동화 도구 도입 시 핫픽스 **many/월 → 5/년**. 단순 convention 으론 부족.

후보: Runway / Xray / 자체 GitHub Action

**현재 상태**: TODO — 도구 평가 + 도입 결정. (mobile 핵심 ROI 안전망)

## Error-Backoff 정책

**Workflow infra 실패** (main-pr-gate / main-post-merge-promote / mobile-cut workflow 자체 실패) → **P0 이슈** + on-call.

### rc → main 머지 차단

| 조건 | 동작 |
|------|------|
| `rc-gate-degraded` (dev-pipeline backoff) | rc → main PR 자동 close + 코멘트 ("nightly recovery 후 재시도") |
| `expand-migrate-contract` 검사 실패 | PR 자동 close |

### mobile-cut 실패

| 상황 | 동작 |
|------|------|
| smoke test 실패 | cut 차단 + 이슈, 직전 main commit cut 시도 (수동) |
| min-version bump 실패 | cut 진행 가능, alert 알림 (수동 bump) |
| Store reject | hotfix PR → cherry-pick → re-submit. release branch 유지 |

### Backend/web auto-deploy 실패 (참고 — 상세는 dev-pipeline)

main 머지와 무관 (이미 dev 에서 deploy 됐음). dev-pipeline 의 error-backoff 참고.

## 결정해야 할 것

- mobile-cut 매월 X 일 (1일 / 첫째 월요일)
- mobile release branch 보존 정책 (영구 / archive 후 삭제)
- cherry-pick 자동화 도구 선정
- mobile build/upload 워크플로우 (Fastlane 자동 vs 수동 단계)

## 관련

- [dev-pipeline.md](./dev-pipeline.md) — auto-deploy 의 진짜 위치
- [rc-promotion.md](./rc-promotion.md) — rc → main PR 의 생성
- [life-of-flag.md](./life-of-flag.md) — flag rollout 은 main 머지와 별도
- [branch-flow.md](./branch-flow.md) — tag 컨벤션 + protection

---
_Reviewed: 2026-05-19 09:47_
