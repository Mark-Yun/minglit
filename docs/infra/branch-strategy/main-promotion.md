# Main Promotion

`rc/YYYY-Wxx` 의 soak 통과 시 `main` 으로 머지, main push 직후 기존 mobile deploy workflow (`deploy-android-*`, `deploy-ios-*`) 가 자동 발동. Backend/web 의 auto-deploy 는 dev 의 rc-gate-pass 에서 이미 일어남 ([dev-pipeline.md](./dev-pipeline.md)). main 머지가 곧 mobile release (hotfix 없으면 weekly).

## 두 가지 이벤트

1. **rc → main 머지** — `rc-soak-check` 가 자동 PR 생성 + 모든 check 통과 시 workflow auto-merge
2. **기존 deploy-* workflow 자동 발동** — main push trigger 로 `deploy-android-{user,partner}`, `deploy-ios-{user,partner}` 가 병렬 실행. store review + staged rollout 은 store-side

## `main-pr-gate`

`rc-soak-check` 가 자동 생성한 promotion PR 에 적용:

| Check | 내용 |
|-------|------|
| `pr-gate` 재실행 | dev-staging-pr-gate 와 동일 — defensive 검증 |
| `expand-migrate-contract` (재검증) | RC 5일 동안 dev 가 더 나갔을 수 있음. 재확인 |
| RC HEAD 의 `rc-gate-pass` status 확인 | 마지막 hotfix 이 rc-gate 통과했는지 |
| `rc-soak-passed` 자동 마커 | rc-soak-check 가 5일 무커밋 확인 후 부여 |

**모든 check 통과 시 workflow 가 auto-merge** (rebase + fast-forward). 어느 하나라도 실패 시 PR hold + Slack 알림 → human 개입 (edge case).

## `main-post-merge-promote`

auto-merge 직후 자동:

```
1. bump-version.sh {ver}  (suffix 제거 — main 은 final version)
2. git commit -m "chore: bump version to v{ver} [skip ci]"
3. git tag v{ver}
4. git tag promo/main-YYYY-Wxx
5. git push (tags + commit)
6. Sentry release marker 부여 (v{ver})
7. Firebase RC `latest_version` = v{ver} (Admin SDK)
```

> Backend/web deploy 는 main 에서 안 함 — dev 의 rc-gate-pass 에서 이미 prod 반영됨. Mobile deploy 는 별도 workflow.

## 기존 Mobile Deploy Workflows (재사용)

main push trigger 로 자동 발동되는 기존 workflows:

| Workflow | 대상 | reusable 호출 |
|----------|------|---------------|
| `deploy-android-user` | Android (app_user) | `shared-android-deploy.yml` |
| `deploy-android-partner` | Android (app_partner) | `shared-android-deploy.yml` |
| `deploy-ios-user` | iOS (app_user) | shared-ios-deploy 가 있는지 확인 (TBD) |
| `deploy-ios-partner` | iOS (app_partner) | 동일 |

**현재 도구**: 기존 workflow 가 어떤 도구 (Fastlane / native CLI / GitHub Action) 쓰는지 그대로 사용. **Fastlane 통일은 후속 (TBD)**.

> Mobile cadence = hotfix 없으면 weekly (rc → main 머지 마다). hotfix 로 RC 가 길어지면 자연스럽게 늦어짐.

## Safety Net 1: Version Kill Switch (Soft + Hard Tier)

**Source of truth**: Firebase RC parameter (client + server 양쪽이 동일 source 에서 fetch).

### 두 Tier

| Tier | 메커니즘 | RC param | Trigger |
|------|----------|----------|---------|
| **2a. Soft kill** | client 가 `latest_version` (RC) 와 자기 버전 비교 + app store 의 새 버전 가용성 확인 후 soft prompt | `latest_version` | `main-post-merge-promote` 가 매 main 머지마다 자동 update |
| **2b. Hard kill** | EF middleware 가 `kill_list_hard` (RC) + `X-App-Version` header 비교 → HTTP 426 reject | `kill_list_hard` | **내부 admin page manual** (catastrophic incident 시 release manager / on-call). 인증·audit log·role 권한·version dropdown 등이 RC 콘솔 직접 변경보다 안전. **admin page 구현은 본 docs scope 밖, 별도 작업 (TBD)** |

### Tier 2a: Soft Kill 흐름

```
[client cold start]
        ↓
[Firebase RC fetch: latest_version]
        ↓
[내 version != latest_version?]
        │
        ├─ no → 정상 사용
        │
        └─ yes → [app store check (Play In-App Update / iOS StoreKit) → 새 버전 사용 가능?]
                        │
                        ├─ yes → soft update prompt + 앱스토어 deep-link
                        │
                        └─ no → 정상 사용 (UX 사고 방지)
```

`latest_version` 은 매 main 머지마다 자동 update. server 가 "최신이 뭐냐" 만 알리고, **누구를 force-update 할지 결정은 클라이언트 + store** (= update 가능한 사람만 prompt 받음).

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

`kill_list_hard` default = `[]` (안전 상태). **변경은 내부 admin page 에서만** — workflow 없음, RC 콘솔 직접 변경도 지양. catastrophic 한 경우만 release manager / on-call 이 admin page 에서 list 추가 + post-mortem + audit log 자동 기록. admin page 의 인증·권한·UX 디테일은 별도 작업.

### 결정해야 할 것

- App store check API 선택 (Play In-App Update / iOS StoreKit 직접 query)
- EF middleware 의 RC cache TTL (5분 vs 1분)
- admin page 의 `kill_list_hard` 변경 권한 (release manager only? on-call 포함?)
- admin page 구현 위치 (landing_admin 신규 vs 기존 앱 내 admin 섹션)
- Firebase App Check 도입 여부 (별개 보안 layer)

**현재 상태**: TODO. EF middleware + mobile dual check + RC parameter 셋업 + Admin SDK 인증.

## Safety Net 2: Expand-Migrate-Contract (재검증)

`main-pr-gate` 에서도 `expand-migrate-contract` CI 재실행 (RC 5일 사이 dev 가 더 나갔을 수 있음). 상세: [dev-staging-pipeline.md](./dev-staging-pipeline.md).

**Policy 요약**:
- N = 6 mobile releases (= 6개월)
- Option C: DB schema 만 검증 (API contract test 는 TBD)
- Destructive op (DROP COLUMN/TABLE, ALTER TYPE) 탐지 + bypass label

## Error-Backoff 정책

**Workflow infra 실패** (main-pr-gate / main-post-merge-promote / deploy-* workflow 자체 실패) → **P0 이슈** + on-call.

### rc → main 머지 차단

| 조건 | 동작 |
|------|------|
| `rc-gate-degraded` (dev-pipeline backoff) | rc → main PR 자동 close + 코멘트 ("recovery 후 재시도") |
| `expand-migrate-contract` 검사 실패 | PR 자동 close |

### Mobile deploy (`deploy-android-*` / `deploy-ios-*`) 실패

| 상황 | 동작 |
|------|------|
| Flutter build 실패 | retry 1회 → `auto-issue` (P1) + mobile 팀 |
| Sign 실패 (cert 만료 / keystore 문제) | `auto-issue` (P0) + mobile 팀 + on-call |
| Store upload 실패 (Fastlane) | retry 1회 → `auto-issue` (P1) |
| Store 검수 reject | mobile 팀이 reject reason 확인 → fix PR via 정상 flow (dev-staging → ... → main → 다음 deploy 사이클) |

### Backend/web auto-deploy 실패 (참고)

main 머지와 무관 (이미 dev 에서 deploy). 상세는 [dev-pipeline.md](./dev-pipeline.md) error-backoff.

## 결정해야 할 것

- Fastlane 설정 (Play `supply`, App Store `pilot`)
- macOS runner 비용 (iOS build 비용 — GitHub-hosted vs self-hosted)
- Code signing cert / keystore 관리 (GitHub secret)
- Crashlytics dSYM / mapping 자동 업로드 도구
- store-side staged rollout 정책 (1%/5%/25%/100% Play 단계 / App Store phased release)
- mobile build + Test Lab smoke 의 위치 (deploy workflow 안 vs 분리)

## 관련

- [dev-pipeline.md](./dev-pipeline.md) — backend/web auto-deploy 의 실제 위치 (dev 의 rc-gate-pass)
- [rc-promotion.md](./rc-promotion.md) — rc → main PR 의 생성
- [life-of-flag.md](./life-of-flag.md) — flag rollout 은 main 머지와 별도
- [branch-flow.md](./branch-flow.md) — tag 컨벤션 + protection
- [specs/workflow-spec.md](./specs/workflow-spec.md) — 기존 deploy-* workflow 의 refactor 상세

---
_Reviewed: 2026-05-19 09:47_
