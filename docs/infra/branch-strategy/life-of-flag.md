# Life of a Flag

Feature flag (Statsig + Firebase Remote Config) 의 생성·soak·rollout·**자동 cleanup** lifecycle. 코드 release (branch promotion) 와 분리된 *기능 release* 의 단일 문서. literature 기반 7개 운영 룰 반영.

## Statsig vs Firebase Remote Config 역할 분담

| 도구 | 용도 | 예시 |
|------|------|------|
| **Statsig** | 실험·gate·layered config·dependent gate | A/B 실험, 권한 gate, staged rollout |
| **Firebase Remote Config** | 단순 config·즉시 kill switch | API base URL, 임계치, cold start fetch, **min-version endpoint** |

**선택 룰**:
- 사용자 cohort 분기 / 메트릭 비교 → Statsig
- 단순 on/off, 값 변경, 빠른 kill switch → Firebase RC
- 둘 다 가능하면 → Statsig
- **둘 다 필요 (kill switch + 실험)**: 결정 트리 명시 필요 (TBD)

**Statsig 사용 룰** (literature gotchas):
- layered experiment → **반드시 `getLayer` API** (`getExperiment` 는 layered 에서 비직관적)
- holdout cohort 의 layer default 는 일반 사용자와 다름을 인지
- **dependent gate depth ≤ 2** (6중 nested = 64 code paths, 테스트 cover 불가)

**Firebase RC 사용 룰** (literature gotchas):
- 기본 fetch interval = 12시간. kill switch 용은 short interval + quota risk 수용
- **cold-start default = 안전 상태 강제** — 첫 cold start 에 server fetch 실패해도 사용자가 신기능 미노출 (default OFF)
- iOS pre-6.3.0 throttle (5 fetches / 60min). `lastFetchStatus` 체크 필수

상세: [../firebase/BLUEDOC.md](../firebase/BLUEDOC.md), [../statsig/BLUEDOC.md](../statsig/BLUEDOC.md)

## Platform 별 Flag 분리

**통합 기능 (backend + mobile 양쪽)** 은 platform 별 별도 flag, **backend 100% prod + 1주 soak 후 mobile 활성화**.

### 명명 컨벤션

```
{area}_{feature}_be    # backend (EF, server-side gating)
{area}_{feature}_mu    # mobile app_user
{area}_{feature}_mp    # mobile app_partner
{area}_{feature}_web   # web (landing) — 있으면
```

### 의존성

- `*_mu`, `*_mp`, `*_web` 는 `*_be` 가 prod 100% + 1주 soak 후에만 5% rollout 시작
- Statsig dependent gate 로 강제

### 4-flag-as-1-Unit Tooling (필수)

**경고**: 4개 flag 를 독립 cleanup 하면 `_be` 만 정리되고 `_mu` 가 영구 50% 고착 (LaunchDarkly 데이터). 다음 tooling 동시 도입:

- flag 생성 시 4개 자동 생성 + sibling hash metadata 로 연결
- cleanup 시 4개 모두 100% & soak 통과 확인 후 일괄 PR 생성
- 4개 중 일부만 stale 한 상태 = monitoring alert
- 월간 sibling 불일치 flag 리스트

**현재 상태**: TODO — tooling spec.

## Flag Lifecycle

```
[0] flag 등록 (4-flag-as-1 tool 이 4개 자동 생성)
    ↓
[1] dev 환경 ON (개발자만, ~1주)
    ↓
[2] prod 카나리 — backend 먼저 (내부 직원 allowlist, ~2주)
    ↓
[3a] backend staged (5% → 25% → 100%, ~1~2주)
    ↓
[3b] backend 100% + 1주 안정 → mobile/web 활성화 게이트 해제
    ↓
[4] mobile/web 카나리 (allowlist, ~2주) → staged (5/25/100%)
    ↓
[5] 전 platform 100% + 1주 안정
    ↓
[6] **30일 후 auto codemod cleanup PR** (4개 flag + 분기 코드 통째 삭제)
```

## Stage 상세

| Stage | Cohort | 기간 | Exit |
|-------|--------|------|------|
| 1. dev | 개발자 (Statsig env=dev / RC condition) | **1주** | rc-gate green + 코드 dev 진입 |
| 2. prod allowlist | 내부 직원 user_id allowlist | **2주** | 카나리 메트릭 OK |
| 3a. backend staged | prod backend 5% → 25% → 100% | 48h → 72h → 7일 | error rate < baseline +X% |
| 3b. backend soak | - | 1주 | 무이슈 (mobile 활성화 게이트) |
| 4. mobile/web | allowlist 2주 → staged 5/25/100% (48h/72h/7일) | ~3~4주 | 동일 룰 |
| 5. 전체 soak | prod 전체 | 1주 | 무이슈 |
| 6. cleanup | - | 30일 후 자동 | codemod PR 자동 생성 |

**왜 dev soak 가 짧고 prod allowlist 가 긴가**: Slack May 2020 outage 처럼 *prod load 와 실 데이터* 에서만 잡히는 버그 다수. dev soak 길이는 효과 약함 (literature).

## 메트릭 게이트

각 staged rollout 단계에서:

- **error rate**: Sentry, baseline +X% 이내 (one-sided sequential testing)
- **crash-free rate**: Firebase Crashlytics, 99.X% 이상 — mobile 가장 신뢰성 높은 신호
- **latency p95**: backend 영향 받는 flag 추가
- **business metric** (결제 성공률 등): 5% 에선 noise 크니 *trip wire* 만, gate X
- **계약 호환 알람**: mobile 활성화 직후 contract mismatch 모니터링

자동 disable 임계: error rate > 5%, p95 > 2s

## Error-Backoff

| 상황 | 동작 |
|------|------|
| canary 메트릭 1회 alert | 자동 hold (다음 단계 차단) + owner 알림 |
| canary 메트릭 2회 연속 | flag flip OFF + 이슈 (`flag-degraded`) |
| staged 5% alert | 자동 rollback (5% → 0%) + owner |
| staged 25% alert | 즉시 rollback to 5% → 0% + on-call |
| staged 100% alert | 즉시 rollback (마지막 안정 단계) + post-mortem |
| mobile 활성화 직후 contract 에러 | mobile flag 즉시 OFF, backend 유지 |

## Cleanup — 가장 critical

**73% 의 "temporary" flag 가 영구화** (Featureflip). 이슈 ping 으론 부족. **codemod-driven auto-PR 필수**.

### 자동 cleanup Flow

```
[100% rollout 통과] → [+30일] → [4-flag-as-1 tool 이 cleanup PR 자동 생성]
                                  ↓
                                  PR 내용:
                                  - 4개 flag 의 Statsig/RC entry archive 표시
                                  - 코드의 flag 분기 통째 제거 (dead branch 까지)
                                  - 관련 test mock 제거
                                  ↓
                                [owner review → merge to dev-staging]
                                  ↓
                                [merge 후 자동으로 Statsig/RC 콘솔 entry 삭제]
```

### Dead Branch 통째 삭제 룰

**Knight Capital ($460M, 45분)**: flag entry 만 지우고 dead branch 코드 남기면 시한폭탄. cleanup PR 은 반드시:
- flag 체크 if/else 의 양쪽 branch 중 사용 안 하는 쪽 **통째 삭제**
- 관련 import / dead function / unused enum 까지 정리
- "혹시 모르니 남겨두자" 금지

### Cleanup 강제

- 30일 auto PR 이 60일까지 머지 안 되면 → `flag-debt` 라벨 + owner manager escalation
- 분기별 flag debt 리뷰 (removed/created ratio, DevCycle 0.8 기준)

## Flag 메타데이터

필수: owner, 생성일, 예상 cleanup 일 (생성일 + 60일), 관련 PR, 관련 metric, sibling flags

## 코드 release vs 기능 release

| 항목 | 코드 release | 기능 release |
|------|--------------|--------------|
| 트리거 | backend/web: dev rc-gate-pass / mobile: main 머지 (deploy-android-*, deploy-ios-*) | flag ON 조작 |
| cadence | backend/web: 시간 단위 / mobile: hotfix 없으면 weekly (rc → main 주기) | feature 별 비동기 |
| rollback | redeploy 이전 commit (분) | flag flip (즉시) |
| 통제 권한 | 릴리즈 매니저 | feature owner |

**원칙**: 새 기능은 flag 뒤에. unflagged 변경은 refactor·infra·security 등 *기능이 아닌 것* 에만. **CI 강제** ([dev-staging-pipeline.md](./dev-staging-pipeline.md) 의 flag-registration).

## 결정해야 할 것

- 카나리 cohort 정의 (내부 직원 group 구체)
- staged rollout 자동 진행 vs 수동 promote
- 메트릭 모니터링 도구 (Statsig 자체 / Grafana / Sentry alert)
- **4-flag-as-1 tooling 구현** (가장 critical TBD)
- RC + Statsig 둘 다 필요 case 결정 트리
- min-version endpoint 와의 연동 (특정 flag 가 min-version bump 요구하는 경우)

## 관련

- [branch-flow.md](./branch-flow.md) — 코드 promotion 의 그림
- [main-promotion.md](./main-promotion.md) — min-version + expand-migrate-contract
- [dev-staging-pipeline.md](./dev-staging-pipeline.md) — flag-registration CI
- [dev-pipeline.md](./dev-pipeline.md) — backend/web auto-deploy
- [test-strategy.md](./test-strategy.md) — flag staged rollout 의 게이트
- [error-detection.md](./error-detection.md) — flag 메트릭의 detection layer
- [../firebase/BLUEDOC.md](../firebase/BLUEDOC.md), [../statsig/BLUEDOC.md](../statsig/BLUEDOC.md)

---
_Reviewed: 2026-05-19 09:47_
