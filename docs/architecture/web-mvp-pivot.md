# Web MVP Pivot (2026-06-06)

> 2026-06-06 Mark 결정. Flutter 모바일 앱 개발을 동결하고 웹 MVP 로 전환하며, 제품 코어를 "이벤트 → 티켓 구매·신청 → 정산" 플로우로 축소한 피벗의 결정 기록이다.
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

웹 MVP 가 검증하는 제품 코어는 아래 한 줄이다 (2026-06-06 2차 축소: QR 체크인/입장권한 제외).

```text
이벤트 생성/수정 ──> 티켓 구매 · 신청/대기 ──> 정산
```

- **유저 웹** (`landing_user` 확장): 탐색 → 이벤트 상세 → 결제/신청 → 구매 내역. QR 티켓 없음 — 입장 확인은 파트너가 참가자 명단으로 수동 처리.
- **파트너 웹** (`landing_partner` 확장): 이벤트/파티 생성·수정 → 신청 승인/거절 → 참가자 명단 → 정산 조회. 멤버/권한 관리·체크인·커스텀 자격심사는 범위 외.
- **파트너 입점은 수동**: 온보딩/입점 신청 플로우 없음 — 당분간 운영자 (admin) 가 직접 파트너 계정을 생성한다.
- **신청 심사는 승인/거절만**: 커스텀 자격 요구 (verification 요구사항 설정·심사) 는 코어에서 제외.
- **법적 필수 영역은 코어에 포함**: 계정/동의 (signup-consent, privacy-protection), 탈퇴 (account-deletion), 환불 (refund-policy-v2), 약관 (partner-terms-privacy).

## 5. Deprecated 기능

코어 검증과 무관한 확장 기능. 코드/문서는 보존하되 신규 작업 금지.

| 기능 | 사유 |
|------|------|
| 매칭/투표/결과 공개 (`event-operation/matching-results-reveal` 등) | 소셜 매칭 레이어 전체를 코어에서 제외 |
| AI 추천·개인화 피드 (`discovery/tag-discovery` 의 AI 부분) | 추천/임베딩 파이프라인 단순화. 기본 태그 탐색은 웹 재설계 시 단순화 재검토 |
| 신뢰 배지 고도화 (`discovery/trust-badge`) | 매칭 전제의 신뢰 시각화 — 코어 외 |
| QR 체크인/입장권한 (`event-operation/partner-qr-checkin-ux`, `ticket-qr-improvement`, `event-now-bar`) | 2차 축소 (2026-06-06): 입장 확인은 참가자 명단 수동 처리로 충분 |
| 파트너 온보딩/입점 신청 플로우 | 운영자 수동 입점으로 대체 |
| 커스텀 자격심사 (verification 요구 설정·심사) | 신청 심사는 승인/거절만 |
| 운영 통계 인프라 (`admin/statistics-tools`) | Supabase 대시보드로 충분 |

기능 자체는 유효하나 Flutter UI 전제라 웹 재설계를 기다리는 것들은 deprecated 가 아니라 **on-hold** 로 구분한다. 분류 전체는 `docs/features/` 각 `prd.md` 최상단 status 배너 참조.

## 6. Phase 로드맵

| Phase | 내용 |
|-------|------|
| **Phase 1 (현재)** | 동결/상태 마킹 (본 문서 + BLUEDOC 배너 + feature status 배너), 유저 웹 MVP 설계·구축 착수 (MDS spec 기반) |
| **Phase 2** | AI 파이프라인 유입 차단만 (event_routes q_vectors/q_tags off + ai-extract-tags cron 해제 — `20260606054500` migration). 매칭/투표 EF 는 EF-gateway 특성상 호출 없으면 idle 이므로 보존 (Mark 결정 2026-06-06) |
| **Phase 3** | 웹 코어 지표 검증 후 확장 기능 재평가 — 매칭/추천 재도입 여부, 모바일 (앱 또는 PWA) 재개 여부 판단 |

## 7. 문서 상태 마킹 컨벤션

`docs/features/<category>/<feature>/prd.md` 최상단 배너 3종:

| 배너 | 의미 |
|------|------|
| `> **Status: web-mvp core (2026-06-06)**` | 코어 플로우 — 웹 MVP 범위 |
| `> **Status: on-hold (mobile frozen, 2026-06-06)**` | 기능 유효, Flutter UI 전제라 웹 재설계 대기 |
| `> **Status: deprecated (web-mvp pivot, 2026-06-06)**` | 코어 외 — 신규 작업 금지 |

배너 없는 feature 는 분류 보류 (판단 필요) 상태다. prd.md 가 없는 legacy 폴더 (entry-group-management, party-entry-group-management, event-detail-empty-state, partner-detail-event-card, notification-settings, purchase-history-color-hierarchy) 는 feature audit 시 일괄 정리한다.

MDS 화면 spec (`apps/mds/docs/public/specs/<screen>/index.html`) 은 `<meta name="feature-status">` 로 같은 분류를 표시한다: `behavior-reference` (모바일 UI 동결, States/조건/에지케이스는 웹 spec 의 behavior 원천) / `on-hold` / `deprecated`. 웹 화면 spec 은 기존 spec 재사용이 아니라 `web_user` / `web_partner` surface 에 신규 작성한다 (`_template_web.html`, responsive 규칙은 `web_foundation_responsive` spec).

## 8. Feature 문서/테스트 마이그레이션 정책

feature 문서는 일괄 재작성하지 않는다. prd.md 와 spec.md 의 CUJ 시나리오는 플랫폼 중립이므로 유지하고, **해당 feature 의 웹 구현 착수 시점에** 아래만 feature 단위로 갱신한다 (웹 화면 spec + spec.md 헤더 + 웹 CUJ 테스트가 한 PR 단위):

| 항목 | 변경 |
|------|------|
| spec.md 헤더 6섹션 | MDS specs → `web_user/web_partner` spec 경로, Apps → `apps/landing_*`, CUJ tests → 웹 e2e 경로 |
| 모바일 전용 CUJ | 푸시 알림·카메라 QR 등 — 웹 동작으로 수정 또는 제거 |
| NFR | "에뮬레이터 baseline" → 웹 baseline (브라우저/뷰포트 명시) 으로 재정의 |
| CUJ 테스트 | `apps/landing_<user|partner>/e2e/cuj/<category>/<feature>.spec.ts` (Playwright 예정) — feature 당 파일 1개, 기존 cujGroup 구조 이식 |

웹 CUJ 가 안정화되면 `dev-rc-cut-gate` 의 required evidence 로 추가한다 (동결된 Flutter CUJ 신호의 대체 — [promotion-contract.md](../infra/branch-strategy/promotion-contract.md) CUJ Contract 참조).

## 9. 웹 MVP 화면 목록 초안

신규 웹 spec 의 출발 목록. `Behavior Source` 는 States/조건/에지케이스를 상속할 기존 모바일 spec.

### web_user (11)

| 화면 | Behavior Source (`apps/mds/docs/public/specs/`) |
|------|------|
| 홈/이벤트 목록 | `home_page`, `event_card` |
| 검색 | `search_page` |
| 이벤트 상세 | `event_detail_page`, `event_bottom_ticket_bar` |
| 파트너 상세 | `partner_detail_page`, `partner_events_page` |
| 신청/결제 위저드 | `event_application_wizard_page`, `ticket_selection_sheet` |
| 신청 상태/구매 내역 | `purchase_history_page`, `purchase_history_detail_page`, `event_application_review_page` |
| 로그인/OAuth 콜백 | `login_page`, `auth_callback_page` |
| 가입 동의 | `signup_consent_page` |
| 본인인증 | `identity_verification_screen` |
| 계정 관리 (마이) | `my_page`, `account_management_page`, `privacy_page` |
| 탈퇴 플로우 | `deletion_info_page`, `deletion_reason_page`, `deletion_verify_page`, `deletion_complete_page` |

### web_partner (8)

| 화면 | Behavior Source |
|------|------|
| 파트너 홈 (오늘 할 일) | `partner_home_page` |
| 파티/이벤트 목록 | `party_list_page`, `party_detail_page` |
| 파티 생성 위저드 | `party_create_wizard_page`, `recurrence_management_screen` |
| 이벤트 생성/수정 | `event_create_page`, `event_edit_page`, `partner_event_detail_page` |
| 티켓 템플릿 관리 | `ticket_create_page`, `ticket_edit_page` |
| 신청 관리 (승인/거절 + 참가자 명단) | `event_application_list_page`, `event_application_manage_page`, `event_application_detail_page` |
| 정산 | `settlement_page`, `settlement_detail_page`, `bank_account_page` |
| 파트너 로그인 | `partner_login_page` |

유저 웹은 모바일웹 우선, 파트너 웹은 데스크톱 우선 (`web_foundation_responsive` 참조).

---

## Related Documents

| 문서 | 내용 |
|------|------|
| [web-client.md](./web-client.md) | 웹 클라이언트 아키텍처 — web_kit, feature-first, 렌더링/테스트 전략 |
| [overview.md](./overview.md) | 시스템 조감도 — EF-only gateway 등 피벗을 가능하게 한 구조 |
| [backend.md](./backend.md) | Supabase 백엔드 (Phase 2 EF 정리의 대상 목록) |
| [architecture-decisions.md](./architecture-decisions.md) | ADR — 백엔드/검색/추천 스택 결정 이력 |
| [docs/features/BLUEDOC.md](../features/BLUEDOC.md) | feature 문서 구조 + status 배너 적용 위치 |
