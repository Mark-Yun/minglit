# Web MVP Pivot (2026-06-06)

> 2026-06-06 Mark 결정. Flutter 모바일 앱 개발을 동결하고 웹 MVP 로 전환하며, 제품 코어를 "이벤트 → 티켓 → 입장 → 정산" 플로우로 축소한 피벗의 결정 기록이다.
> 각 BLUEDOC 의 동결 배너와 `docs/features/` 의 status 배너는 이 문서를 기준으로 한다.

---

## 1. 결정 배경

- Flutter 모바일 앱 2개 (`app_user`, `app_partner`) 의 개발·배포·스토어 운영 부담이 솔로 파운더 + AI-first 구조 대비 과도하다 ([ai-first-principle.md](../background/ai-first-principle.md) §1 — "운영 부담을 낮추는 결정 우선").
- 매칭/투표·AI 추천 등 확장 기능이 코어 가치 검증 (이벤트에 사람이 모이고 돈이 도는가) 보다 앞서 구현 비용을 소모하고 있었다.
- 백엔드가 EF-only gateway 원칙 ([overview.md §2.2](./overview.md#22-ef-only-원칙-mutation-gateway)) 으로 클라이언트와 분리돼 있어, 클라이언트를 웹으로 교체해도 Supabase 백엔드는 거의 그대로 재사용 가능하다 — 피벗 비용이 낮은 구조적 시점.

## 2. 동결 대상 (Frozen)

코드는 working tree 에 유지하되 (스냅샷: `archive/flutter-apps` 브랜치) 더 이상 개발/배포하지 않는다.

| 대상 | 비고 |
|------|------|
| `apps/app_user/` · `apps/app_partner/` | Flutter 모바일 앱 2개. 스토어 배포 중단 |
| `shared/packages/minglit_kit/` | 앱 공용 Flutter 패키지. UI 레이어 동결 — 단, Repository·EF 호출 계약은 웹 구현의 reference 로 활용 |
| CUJ 테스트 인프라 | `apps/*/integration_test/cuj/` — Flutter integration_test + 에뮬레이터 기반이라 앱과 함께 동결 |

## 3. 유지 대상 (Kept)

| 대상 | 비고 |
|------|------|
| `supabase/` 백엔드 전체 | DB·EF·트리거·크론 그대로 재사용. 비-코어 EF 비활성화는 Phase 2 에서 별도 처리 |
| `apps/mds/` MDS spec | 웹 화면의 디자인 명세 (SSoT) 로 계속 사용 |
| `apps/landing_user/` · `apps/landing_partner/` | Next.js 랜딩 + 약관/처리방침 (법적 필수) |
| `docs/` 설계·법무·운영 문서 | status 마킹으로 유효 범위 표시 (삭제하지 않음) |

## 4. 코어 플로우 정의

웹 MVP 가 검증하는 제품 코어는 아래 한 줄이다.

```text
이벤트 생성/수정 ──> 티켓 구매 · 신청/대기 ──> 입장 권한 (QR 체크인) ──> 정산
```

- **유저 웹**: 기존 유저앱 흐름 (탐색 → 이벤트 상세 → 결제/신청 → 내 티켓/QR) 을 거의 유지하며 웹으로 옮긴다.
- **파트너 측**: 추후 재조정 — admin console 수준으로 축소될 가능성 있음 ([admin-dashboard PRD](../features/admin/admin-dashboard/prd.md) 의 `apps/admin_web/` 방향과 정렬).
- **법적 필수 영역은 코어에 포함**: 계정/동의 (signup-consent, privacy-protection), 탈퇴 (account-deletion), 환불 (refund-policy-v2), 약관 (partner-terms-privacy).

## 5. Deprecated 기능

코어 검증과 무관한 확장 기능. 코드/문서는 보존하되 신규 작업 금지.

| 기능 | 사유 |
|------|------|
| 매칭/투표/결과 공개 (`event-operation/matching-results-reveal` 등) | 소셜 매칭 레이어 전체를 코어에서 제외 |
| AI 추천·개인화 피드 (`discovery/tag-discovery` 의 AI 부분) | 추천/임베딩 파이프라인 단순화. 기본 태그 탐색은 웹 재설계 시 단순화 재검토 |
| 신뢰 배지 고도화 (`discovery/trust-badge`) | 매칭 전제의 신뢰 시각화 — 코어 외 |

기능 자체는 유효하나 Flutter UI 전제라 웹 재설계를 기다리는 것들은 deprecated 가 아니라 **on-hold** 로 구분한다 (예: event-now-bar, ticket-qr-improvement). 분류 전체는 `docs/features/` 각 `prd.md` 최상단 status 배너 참조.

## 6. Phase 로드맵

| Phase | 내용 |
|-------|------|
| **Phase 1 (현재)** | 동결/상태 마킹 (본 문서 + BLUEDOC 배너 + feature status 배너), 유저 웹 MVP 설계·구축 착수 (MDS spec 기반) |
| **Phase 2** | 비-코어 EF/크론 비활성화 (매칭·추천·임베딩 파이프라인), 파트너 측 재조정 (admin console 통합 여부 결정), Flutter 관련 CI 정리 |
| **Phase 3** | 웹 코어 지표 검증 후 확장 기능 재평가 — 매칭/추천 재도입 여부, 모바일 (앱 또는 PWA) 재개 여부 판단 |

## 7. 문서 상태 마킹 컨벤션

`docs/features/<category>/<feature>/prd.md` 최상단 배너 3종:

| 배너 | 의미 |
|------|------|
| `> **Status: web-mvp core (2026-06-06)**` | 코어 플로우 — 웹 MVP 범위 |
| `> **Status: on-hold (mobile frozen, 2026-06-06)**` | 기능 유효, Flutter UI 전제라 웹 재설계 대기 |
| `> **Status: deprecated (web-mvp pivot, 2026-06-06)**` | 코어 외 — 신규 작업 금지 |

배너 없는 feature 는 분류 보류 (판단 필요) 상태다. prd.md 가 없는 legacy 폴더 (entry-group-management, party-entry-group-management, event-detail-empty-state, partner-detail-event-card, notification-settings, purchase-history-color-hierarchy) 는 feature audit 시 일괄 정리한다.

---

## Related Documents

| 문서 | 내용 |
|------|------|
| [overview.md](./overview.md) | 시스템 조감도 — EF-only gateway 등 피벗을 가능하게 한 구조 |
| [backend.md](./backend.md) | Supabase 백엔드 (Phase 2 EF 정리의 대상 목록) |
| [architecture-decisions.md](./architecture-decisions.md) | ADR — 백엔드/검색/추천 스택 결정 이력 |
| [docs/features/BLUEDOC.md](../features/BLUEDOC.md) | feature 문서 구조 + status 배너 적용 위치 |
