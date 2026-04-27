# Minglit Domain Glossary

> **목적**: 코드와 문서에서 추출한 기술적 정의(WHAT). 비즈니스 의미(WHY)는 `<TODO:>` 플레이스홀더로 표시.
> **정렬**: 영문명 알파벳순.

---

## 관계 다이어그램

```text
Party (템플릿)
  └── Event (회차 인스턴스)
        └── EntryGroup (입장 그룹)
              └── EventApplication (신청)
                    ├── VerificationSubmission (자격 심사)
                    └── Ticket (발권 → event_participants)
                          └── Check-in (체크인 확인)
                                └── MatchVote → MatchPair (매칭)
```

---

## 용어 사전

---

### Application (이벤트 신청)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 신청 / 이벤트 신청 |
| **코드명** | `EventApplication` |
| **기술적 정의** | 특정 유저가 특정 이벤트의 특정 티켓에 참가를 요청한 레코드. `status`(pending / approved / rejected / cancelled / paid / payment_failed / payment_pending)와 `refund_status`(none / requested / completed / failed)를 독립적으로 추적. 결제 완료 시 `on_application_approval` 트리거가 `event_participants`에 티켓을 자동 발권. |
| **코드 위치** | `shared/packages/minglit_kit/lib/src/data/models/event_application.dart`, `supabase/migrations/` `04_schema_commerce` 섹션, `event_applications` 테이블 |
| **관련 용어** | Event, Ticket, VerificationSubmission, Refund, Settlement |
| **비즈니스 의미** | **이벤트 신청 → 즉시 결제 → 자동 또는 승인 후 참가**. 사용자가 신청하면 즉시 결제 (지연 없음). 그 이벤트의 EntryGroup이 요구하는 Qualification을 이미 통과한 사용자는 결제 즉시 참가자에 자동 추가. Qualification이 부족한 사용자는 Partner 수동 승인 대기 → 승인 시 참가 추가, 거부 시 자동 환불. 즉, Qualification = 자동/수동 분기점. |

---

### AppRouter

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 앱 라우터 |
| **코드명** | `AppRouter` / `goRouterProvider` |
| **기술적 정의** | GoRouter 기반 타입-세이프 라우팅 진입점. `app_router.dart`에 정의되며 `goRouterProvider`로 Riverpod에서 참조. 인증·동의·온보딩 상태를 기반으로 리다이렉트 로직을 수행하는 가드(guard)를 내장. Graphify에서 41 edges를 가진 god node. |
| **코드 위치** | `apps/app_user/lib/src/app_router.dart`, `apps/app_partner/lib/src/app_router.dart` |
| **관련 용어** | Coordinator, minglit_kit |
| **비즈니스 의미** | > **기술 정의** (코드 기반): GoRouter 기반 앱 전체 라우팅 진입점으로, 인증·동의 상태를 실시간 감지해 화면 접근을 제어하는 중앙 가드 레이어.<br><br>> **현재 패턴**:<br>> - 라우트 정의는 `app_routes.dart`에 `@TypedGoRoute` 어노테이션으로 feature별로 중앙 집중 정의 (`$appRoutes`로 GoRouter에 주입); feature별 분산 아님<br>> - `app_router.dart`의 `redirect` 콜백이 인증(`currentUserProvider`), 동의(`hasRequiredConsentsProvider`), 경로 prefix/suffix 매칭으로 보호된 경로를 게이트<br>> - `goRouterProvider`로 Riverpod에서 참조하며, `authStateChangesProvider`·`hasRequiredConsentsProvider` 변경 시 `ValueNotifier`로 라우터 자동 갱신<br>> - `MinglitNavigationObserver` + `MinglitPageTransitions`(sharedAxisScaled)로 앱 전체 네비게이션 이벤트 추적 및 화면 전환 통일<br><br>> **결정 (Q26)**: 현재 centralized 유지. 분리 트리거 — `app_routes.dart` 500+ 라인 OR merge 충돌 빈도 ↑ OR feature별 lazy loading 필요 시. 그 시점에 feature별 `XxxRoutes()` 함수로 split + 중앙 register 패턴으로 점진 이행. 지금은 over-engineering 회피. |

---

### Check-in (체크인)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 체크인 |
| **코드명** | `event-checkin` (Edge Function), `event_participants.checked_in_at` |
| **기술적 정의** | 이벤트 참가자가 실제 현장에 도착했음을 확인하는 절차. 파트너 앱에서 QR 스캔 또는 수동 체크인으로 처리. `event_participants` 테이블의 `checked_in_at` 컬럼(2026-04-24 마이그레이션 추가)에 시각이 기록됨. 체크인 완료 참가자를 대상으로 `event-matching` Edge Function이 매칭 페어를 생성. |
| **코드 위치** | `supabase/functions/event-checkin/`, `supabase/migrations/20260424000003_add_checked_in_at_to_event_participants.sql`, `supabase/migrations/20260424000004_create_checkin_rpcs.sql` |
| **관련 용어** | Event, Matching, MatchPair |
| **비즈니스 의미** | 두 가지 게이트 동시: 1) **매칭 자격 게이트** — 체크인 한 사람만 MatchVote 가능. No-show는 매칭 풀에서 제외 → "실제 출석한 사람끼리만 매칭" 정책 보장. 2) **Partner 정산 대상** — 체크인 된 참가자만 정산 산정에 포함. 결제는 했지만 No-show면 정산 제외 (분쟁 시 환불 처리). Ed25519 QR 서명으로 위변조 방지. |

---

### Coordinator (Flutter 패턴)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 코디네이터 |
| **코드명** | `*Coordinator` (예: `EventCoordinator`, `PartyCoordinator`, `PaymentCoordinator`) |
| **기술적 정의** | Flutter 앱에서 UI와 라우팅 로직을 분리하는 패턴. UI 위젯은 어디로 이동할지 모르고 Coordinator에게 이벤트만 전달. Coordinator가 GoRouter의 타입-세이프 Route 클래스를 호출하여 화면 전환을 수행. 항상 특정 앱 feature 폴더에 위치하며 `minglit_kit`에 두지 않는다. |
| **코드 위치** | `apps/app_user/lib/src/features/*/logic/*_coordinator.dart`, `apps/app_partner/lib/src/features/*/logic/*_coordinator.dart` |
| **관련 용어** | AppRouter, minglit_kit, Repository |
| **비즈니스 의미** | > **기술 정의** (코드 기반): GoRouter와 UI 위젯 사이의 네비게이션 중간자 — 위젯은 어디로 갈지 모르고 Coordinator에 이벤트를 위임하며, Coordinator가 타입-세이프 Route 클래스를 통해 실제 화면 전환을 수행하는 단방향 의존 패턴.<br><br>> **현재 패턴**:<br>> - Coordinator는 `GoRouter` 인스턴스를 생성자에서 받고 (`goRouterProvider`), Riverpod `@riverpod`으로 제공됨; `minglit_kit`에 두지 않고 각 앱 feature 폴더 `features/*/logic/*_coordinator.dart`에 위치<br>> - 메서드 구성: `push*()`(스택에 쌓기) vs `go*()`(스택 교체) 두 종류의 GoRouter 호출을 명확히 구분; `showTicketSelection()`처럼 Bottom Sheet 표시도 Coordinator가 담당<br>> - cross-feature 네비게이션도 Coordinator 경계 안에서 처리 (예: `EventCoordinator.pushLogin()`, `goToPurchaseHistory()`) — feature 간 직접 참조 대신 Coordinator 내부로 위임<br><br>> **결정 (Q27)**: 현재 app별 feature 폴더 유지. Navigation은 app-specific (app_user vs app_partner는 다른 제품). **공유 추출은 exception으로만** — 같은 Coordinator 패턴이 두 앱에 중복 발생할 때 (예: AuthCoordinator) 그 개별만 minglit_kit으로 추출. Default = app별, exception = 중복 시 공유. |

---

### EntryGroup (입장 그룹)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 입장 그룹 |
| **코드명** | `EntryGroup` |
| **기술적 정의** | 특정 이벤트(Event)에 소속된 참가 조건 그룹. `gender`(male/female/null), `birth_year_min`, `birth_year_max`, `required_verification_ids`로 구성. `entry_groups` 테이블에 저장. 파티 생성 시 `EntryGroupTemplate`에서 복사하여 생성. |
| **코드 위치** | `shared/packages/minglit_kit/lib/src/data/models/party_entry_group.dart` (`EntryGroup` class), `entry_groups` 테이블 |
| **관련 용어** | EntryGroupTemplate, Event, Party, Verification |
| **비즈니스 의미** | **입장 조건이자 참여자 분류** (이중 역할). 예: 남성 그룹 + 여성 그룹으로 나뉜 로테이션 모임에서 각각이 EntryGroup. Partner가 EntryGroup을 정의하면, 매칭 룰을 그룹 기반으로 세팅 가능 — `A → B` (A 그룹이 B 그룹과 매칭 시도), `B → A` (반대 방향). 이게 로테이션 소개팅의 "그룹 vs 그룹" 메커닉을 그대로 코드화한 것. |

---

### EntryGroupTemplate (입장 그룹 템플릿)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 입장 그룹 템플릿 |
| **코드명** | `EntryGroupTemplate` |
| **기술적 정의** | 파티(Party) 레벨에서 정의하는 입장 조건 템플릿. 이벤트 생성 시 `EntryGroup`으로 복사됨. `entry_group_templates` 테이블에 저장. `party_id`를 FK로 보유. |
| **코드 위치** | `shared/packages/minglit_kit/lib/src/data/models/party_entry_group.dart` (`EntryGroupTemplate` class), `entry_group_templates` 테이블 |
| **관련 용어** | EntryGroup, Party |
| **비즈니스 의미** | **Party 레벨에서 정의되는 EntryGroup 양식**. Party가 Event를 만들 때 EntryGroupTemplate이 EntryGroup 인스턴스로 복사됨. Template은 "이 Party는 어떤 그룹 구조로 운영되는가"의 정의 (예: "남성/여성 2그룹"), 실제 그룹은 매 Event마다 별도 인스턴스로 생성. 이렇게 분리하면 Template 변경이 과거 Event에 영향 X, Event는 자기 시점의 그룹 상태 보존. |

---

### Event (이벤트)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 이벤트 |
| **코드명** | `Event` |
| **기술적 정의** | Party(템플릿)로부터 생성된 실제 이벤트 회차. `start_time`, `end_time`, `status`(scheduled → active → ongoing → completed / cancelled), `current_participants`, `max_participants`를 독립적으로 관리. `events` 테이블에 저장. 상태 전환은 pg_cron 크론잡이 자동 수행하며 클라이언트가 직접 `status`를 UPDATE하지 않는다. |
| **코드 위치** | `shared/packages/minglit_kit/lib/src/data/models/event.dart`, `events` 테이블 |
| **관련 용어** | Party, EntryGroup, Ticket, Application, Settlement |
| **비즈니스 의미** | **사용자가 실제로 참여하는 1회 모임**. 사용자 관점에서 minglit의 1차 entity. Party 템플릿에서 정보를 복사해서 생성됨. 실제 시간/장소/참여자가 결정되는 단위. 로테이션 소개팅 1세션 = 1 Event. |

---

### Identity Verification (신원 인증, Layer 1)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 본인인증 / 신원 인증 |
| **코드명** | `identity-verify` (Edge Function), `is_verified` 필드 |
| **기술적 정의** | 2-layer 신뢰 모델의 1레이어. Portone V2 PASS/SMS API를 통해 유저의 실존 여부와 나이·성별을 플랫폼이 검증. 결과는 `user_profiles.is_verified = true`로 기록되며, `ci_encrypted`(pgp_sym_encrypt), `di_encrypted`, `di_hash`(SHA-256)를 저장. |
| **코드 위치** | `supabase/functions/identity-verify/`, `user_profiles` 테이블 |
| **관련 용어** | Verification (Layer 2: Qualification), Partner |
| **비즈니스 의미** | minglit 플랫폼 자체에 들어오기 위한 **최소 본인인증** (PASS, 통신사 KYC). 모든 사용자 공통. 법적/플랫폼 표준 의무 — 실존 인물임을 보장하는 최하위 신뢰선. Identity 없이 Qualification 심사는 의미 없으므로 선행 필수. |

---

### MatchPair (매칭 결과)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 매칭 결과 |
| **코드명** | `MatchPair` |
| **기술적 정의** | 두 유저가 서로 투표했을 때 자동 생성되는 매칭 성사 레코드. `match_pairs` 테이블에 `user_lower_id < user_higher_id` 형태로 중복 없이 저장. 생성 후 `get_matched_user_info()` RPC로 상대방 연락처에 접근 가능. |
| **코드 위치** | `shared/packages/minglit_kit/lib/src/data/models/matching.dart` (`MatchPair` class), `match_pairs` 테이블 |
| **관련 용어** | MatchVote, MatchRule, Check-in |
| **비즈니스 의미** | **이벤트 참여자끼리 마음에 드는 상대를 지목 → 양방향 일치 시 자동 매칭**의 최종 결과물. 이벤트 종료 후(또는 진행 중) 참여자가 투표 → 시스템이 mutual interest 검출 → MatchPair 자동 생성. 로테이션 소개팅의 핵심 가치 = "자동 매칭 결과 정리". |

---

### MatchRule (매칭 규칙)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 매칭 규칙 |
| **코드명** | `MatchRule` |
| **기술적 정의** | 이벤트 내에서 어떤 입장 그룹이 어떤 그룹에게 투표할 수 있는지를 정의하는 규칙. `source_group_id → target_group_id` 방향으로 설정하며 `vote_count`로 그룹별 투표 수를 제한. 파트너가 `partner-manage-match` Edge Function으로 관리. |
| **코드 위치** | `shared/packages/minglit_kit/lib/src/data/models/matching.dart` (`MatchRule` class), `match_rules` 테이블 |
| **관련 용어** | MatchVote, MatchPair, EntryGroup |
| **비즈니스 의미** | Partner가 "어떤 그룹이 어떤 그룹을 vote 가능한지"를 정의하는 규칙 (보통 EntryGroup A → EntryGroup B). 로테이션 소개팅의 "그룹 vs 그룹" 구조를 그대로 코드화. `vote_count`는 그룹별 투표 수 상한선 — 예: 남성 그룹이 여성 그룹 중 최대 3명에게만 투표 가능. |

---

### MatchVote (매칭 투표)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 매칭 투표 |
| **코드명** | `MatchVote` |
| **기술적 정의** | 유저가 이벤트 내에서 다른 유저에게 보내는 단방향 투표 레코드. `match_votes` 테이블에 `voter_id → candidate_id`로 저장. `cast_match_vote()` RPC가 advisory lock으로 원자적 투표와 상호 매칭 감지를 수행. 상호 투표 확인 시 `match_pairs`가 자동 생성됨. |
| **코드 위치** | `shared/packages/minglit_kit/lib/src/data/models/matching.dart` (`MatchVote` class), `match_votes` 테이블 |
| **관련 용어** | MatchRule, MatchPair |
| **비즈니스 의미** | 이벤트 참여자가 다른 참여자에게 보내는 "마음에 든다" 단방향 지목. MatchRule이 허용하는 방향(예: 남→여)으로만 투표 가능. 상호 투표 확인 시 MatchPair 자동 생성 — 로테이션 소개팅의 쪽지/카드 교환을 디지털화한 것. |

---

### Staff (파트너 스태프)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 파트너 스태프 |
| **코드명** | `partner_member_permissions` (테이블), `partner_role` (enum) |
| **기술적 정의** | 파트너 조직에 소속된 유저. `role`은 owner / manager / staff 3단계이며, `permissions[]` 배열로 세분화된 권한을 관리. role 변경 시 `trigger_sync_permissions` 트리거가 permissions를 자동 동기화. |
| **코드 위치** | `partner_member_permissions` 테이블, `supabase/migrations/` `02_schema_core` 섹션 |
| **관련 용어** | Partner |
| **비즈니스 의미** | Partner 조직 내 역할 분리. **owner**: 모든 권한 — Partner 등록, 정산 계좌, Staff 추가/제거. **manager**: Party/Event 생성 + 수정 권한 (운영 구조 결정 권한). **staff**: Party 운영만 — 체크인 처리 + Application 승인/거부 (현장 실무자). 분리 의도: 사장/매니저/현장 알바 같은 일반적인 매장 운영 구조 그대로 모델링. 코드명은 `partner_member_permissions`이지만 사용자 facing 용어는 "Staff"로 통일 (Member는 사용자/참가자와 혼동 회피). |

---

### minglit_kit

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 밍글릿 킷 |
| **코드명** | `minglit_kit` (Dart package) |
| **기술적 정의** | 모노레포에서 `app_user`와 `app_partner` 두 앱이 공유하는 핵심 Dart 패키지. 도메인 모델, Repository 클래스, 공유 UI 위젯, Riverpod Provider, 에러 처리 유틸리티를 포함. 4개의 barrel module(`minglit_kit.dart`, `minglit_core.dart`, `minglit_data.dart`, `minglit_logic.dart`)로 구성. |
| **코드 위치** | `shared/packages/minglit_kit/lib/` |
| **관련 용어** | Repository, Coordinator, AppRouter |
| **비즈니스 의미** | > **기술 정의** (코드 기반): `app_user`와 `app_partner` 두 앱이 공통으로 사용하는 도메인 모델·Repository·공유 UI·Riverpod Provider를 4개 barrel로 캡슐화한 Dart 모노레포 패키지.<br><br>> **현재 패턴**:<br>> - 4개 barrel 모듈로 계층 분리: `minglit_core`(설정·유틸·예외), `minglit_data`(모델·Repository 전체 + Supabase 의존), `minglit_logic`(Riverpod Provider·Controller), `minglit_ui`(공유 위젯·테마·페이지)<br>> - **들어가는 것**: 도메인 모델(`Event`, `Party`, `Ticket` 등), 모든 Repository, 공용 UI 위젯(`MinglitButton`, `MinglitDialog` 등), 인증/체크인/알림 등 양 앱 공통 feature 로직<br>> - **들어가지 않는 것**: Coordinator (앱별 라우팅이 달라 앱 내부 위치), 앱별 화면(예: `EventDetailPage`는 app_user 전용), Coordinator에서 쓰는 앱 전용 Route 정의<br>> - `minglit_dev.dart` 별도 barrel로 dev-only export 격리 (명시적 import 필요)<br><br>> **결정 (Q28)**: minglit_kit 포함 기준 = **"두 앱 모두 사용한다"가 유일 조건**. 디자인 시스템 원자/분자 같은 계층 분류는 별도 적용 안 함.
>
> **현재 진행 중**: MDS (Mobile Design System) 추출 프로젝트가 별도로 진행 중 — 향후 `minglit_kit/ui`의 일부가 MDS 패키지로 이관될 가능성. UI 위젯 추가/수정 PR 시 MDS 이관 대상인지 검토. |

---

### Party (파티)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 파티 |
| **코드명** | `Party` |
| **기술적 정의** | 이벤트의 템플릿 역할을 하는 엔티티. 제목, 설명(Quill Delta JSON), 이미지, 장소, 입장 그룹 템플릿, 티켓 템플릿, 태그를 보유. `status`(draft / active / closed)와 `visibility`(public / private)를 가짐. 파티 하나에서 여러 회차의 이벤트(Event)를 생성. `parties` 테이블에 저장. |
| **코드 위치** | `shared/packages/minglit_kit/lib/src/data/models/party.dart`, `parties` 테이블 |
| **관련 용어** | Event, EntryGroupTemplate, TicketTemplate, Tag, Partner |
| **비즈니스 의미** | **이벤트 템플릿**. 정기적/반복적으로 운영되는 모임 시리즈를 표현. 사용자 화면에는 Party 자체는 잘 노출 안 되고 주로 그 아래 Event들이 보임. Partner가 한 번 Party를 만들면 그 정보를 복사해서 여러 Event를 생성. "Party = 이벤트의 셋"이 본질. 명칭 자체에 큰 의미는 없음. |

---

### Payment Mode (결제 경로)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 결제 경로 |
| **코드명/필드** | `payment_provider` 또는 결제 모드 구분 필드 (코드 위치 확인 필요) |
| **기술적 정의** | 플랫폼 결제 (Platform Payment) — minglit이 PortOne 통해 결제 받고 정산 → Partner. 환불 자동화 가능. minglit 수수료 ~10%. 파트너 직접 결제 (Partner Direct Payment) — Partner가 자체 채널(현금, 계좌이체, 자체 PG 등)로 결제 받음. minglit은 attendance/matching만 추적. 환불 수동 (Partner 직접 처리). |
| **코드 위치** | `<TODO: 정확한 코드 위치 + 두 모드의 데이터 차이 확인 필요>` |
| **관련 용어** | Refund, Settlement, Application |
| **비즈니스 의미** | Partner마다 결제 인프라/선호도 다름. 플랫폼 강제하면 가입 진입장벽 상승. 결제 모드별 환불·정산·법적 의무가 다름 (Refund 항목 참조). |

---

### Partner (파트너)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 파트너 |
| **코드명** | `Partner` (모델), `partners` (테이블) |
| **기술적 정의** | 파티/이벤트를 개설하는 주최 조직. `name`, `biz_number`, `portone_partner_id`, `is_active` 컬럼을 가짐. 입점 신청(`partner_applications`) → 플랫폼 moderator 승인 → `partners` 레코드 활성화 순서로 온보딩. |
| **코드 위치** | `shared/packages/minglit_kit/lib/src/data/models/partner.dart`, `partners` 테이블 |
| **관련 용어** | Staff, Party, Verification, Settlement |
| **비즈니스 의미** | **모임 주최자**. 일반적으로 B2B (사업자/전문 주최자)이지만 **같은 사람이 Partner와 User 역할 모두 수행 가능** (평소엔 참가자, 가끔 주최자). app_partner/app_user 별도 앱이지만 같은 supabase auth user. Partner 화면에서는 자기 모임 운영 + 정산 관리, **User** 화면에서는 다른 모임 참가. |

---

### Qualification Verification (자격 인증, Layer 2)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 자격 인증 |
| **코드명** | `Verification`, `VerificationSubmission`, `partner_verified_users` |
| **기술적 정의** | 2-layer 신뢰 모델의 2레이어. 특정 파티/티켓 참가 자격(직장, 학력, 자산, 결혼, 차량 등)을 파트너가 직접 심사. `verifications`(양식 정의) → `user_verifications`(유저 서랍) → `verification_submissions`(제출) → `partner_verified_users`(승인 결과) 순서로 처리. 만료 가능(`valid_until`). |
| **코드 위치** | `shared/packages/minglit_kit/lib/src/data/models/verification.dart`, `shared/packages/minglit_kit/lib/src/data/models/verification_submission.dart`, `verifications` / `verification_submissions` / `partner_verified_users` 테이블 |
| **관련 용어** | Identity Verification (Layer 1), Application, Partner |
| **비즈니스 의미** | Partner들이 자기 모임의 기준에 맞춰 사용자를 추가 검증하는 레이어 (예: "직장인 인증", "특정 학력 인증", "결혼 안 한 사람만"). Partner마다 다른 룰. Identity는 법적/플랫폼 표준, Qualification은 비즈니스 차별화 도구. 분리한 이유: 법적 의무와 비즈니스 자유도를 섞으면 둘 다 망가짐. |

---

### Recommendation (추천)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 추천 / 개인화 추천 |
| **코드명** | `get_personalized_recommendations()` (RPC), `pgvector`, `ai-embed` (Edge Function) |
| **기술적 정의** | OpenAI text-embedding-ada-002 모델로 생성한 1536차원 벡터를 `party_embeddings`와 `user_embeddings`에 HNSW 인덱스로 저장하고, 코사인 유사도(`<=>` 연산자)로 유저에게 맞는 파티를 추천. 벡터 생성은 PGMQ `q_vectors` 큐를 통한 비동기 파이프라인으로 처리. |
| **코드 위치** | `supabase/functions/ai-embed/`, `party_embeddings` / `user_embeddings` 테이블, `docs/architecture/search-and-recommendation.md` |
| **관련 용어** | Tag (PGroonga 검색), Party, Event |
| **비즈니스 의미** | **개인화된 이벤트 피드**. 추천 대상: 이벤트 (사용자가 발견하고 신청할 수 있는 항목). 추천 시드: 사용자가 본 파티 + 참가신청한 파티의 임베딩을 가중치로 사용자 임베딩 계산 → 그 임베딩과 가까운 이벤트. 신규 사용자 (임베딩 없음): 인기 기반 추천 (cold-start fallback). 사용자 → 다른 사용자 추천이나 Partner 추천은 현재 없음 (이벤트만). |

---

### RecurrenceRule (반복 이벤트 규칙)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 반복 이벤트 규칙 |
| **코드명** | `RecurrenceRule` |
| **기술적 정의** | 파티에 연결된 이벤트 자동 생성 규칙. `pattern`(weekly / biweekly / monthly), `days_of_week[]`, `start_time`, `end_time`, `end_date`를 정의. `recurrence-cron` Edge Function이 매일 UTC 00:00에 향후 30일분 이벤트를 자동 생성. 규칙 상태: active / paused / cancelled. |
| **코드 위치** | `shared/packages/minglit_kit/lib/src/data/models/recurrence_rule.dart`, `recurrence_rules` 테이블, `supabase/functions/recurrence-cron/` |
| **관련 용어** | Party, Event |
| **비즈니스 의미** | **정기 반복 이벤트 자동 생성 룰**. 주된 use case: **매월 1회 정기 모임을 운영하는 Partner**가 매번 새 Event 만드는 수고 없이 Party 한 번 셋업 후 계속 돌리고 싶을 때. 즉 "이벤트 운영 자동화 = Partner retention"의 핵심 도구. 기대 비율: 사업자 Partner의 다수가 활용 (지속 운영 모델). |

---

### Refund (환불)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 환불 |
| **코드명** | `refund_status` (필드), `payment-cancel` (Edge Function) |
| **기술적 정의** | 이원화 구조로 운영. 1) 플랫폼 자동 환불: 파트너가 신청을 거절 시 `on_application_rejected` 트리거가 `payment-cancel` EF를 pg_net으로 호출. 2) 파트너 수동 환불: 파트너 앱에서 직접 요청. `refund_status`: none → requested → completed / failed. |
| **코드 위치** | `supabase/functions/payment-cancel/`, `event_applications.refund_status` 컬럼, `docs/architecture/payment-pipeline.md §5` |
| **관련 용어** | Application, Settlement |
| **비즈니스 의미** | **결제 경로별 이중 정책**. 플랫폼 결제 환불 (자동): 사용자가 앱에서 직접 환불 가능. 조건: 결제 후 2시간 이내 OR 이벤트 시작 7일 전. 즉시 자동 처리. minglit 수수료도 전액 환불. 파트너 직접 결제 환불 (수동): 사용자가 Partner에 직접 연락 → Partner 승인 → 환불. 약간의 허들을 둬서 즉흥 환불 어렵게 (의도적 마찰). 단 한국 약정 의무 법령에 따라 사용자에게 유리한 조건 적용. 7일 = 전자상거래법 청약철회 base + 운영 buffer로 설정. |

---

### Repository (리포지토리)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 리포지토리 |
| **코드명** | `*Repository` (예: `EventRepository`, `PartnerRepository`, `PartyRepository`) |
| **기술적 정의** | Supabase SDK 호출을 추상화하는 데이터 접근 레이어. UI와 Provider가 Supabase를 직접 호출하지 않고 Repository를 통해서만 데이터에 접근. 300줄 초과 시 Dart `part`/`mixin` 패턴으로 query/command 분리. `minglit_kit`에서 공유되며 Riverpod Provider로 제공. Graphify에서 `EventRepository`가 40 edges를 가진 god node. |
| **코드 위치** | `shared/packages/minglit_kit/lib/src/data/repositories/` |
| **관련 용어** | minglit_kit, Coordinator |
| **비즈니스 의미** | > **기술 정의** (코드 기반): Supabase SDK 직접 호출을 앱 코드에서 격리하는 데이터 접근 레이어 — UI·Provider는 Repository 메서드만 호출하고 Supabase 쿼리/RPC 세부사항을 모른다.<br><br>> **현재 패턴**:<br>> - 추상 base class + impl 분리 없이 **concrete class 단일 구현** (`EventRepository extends _SupabaseEventContextBase`) — abstract interface + Supabase impl 패턴은 미사용<br>> - 300줄 초과 시 `part` 파일로 query/command 분리 (`event_repository_queries.dart` / `event_repository_commands.dart`), mixin으로 조합<br>> - DataSource 중간 레이어 없음 — Repository가 직접 `supabaseClient.rpc()` / `.from().select()` 호출<br>> - `@Riverpod(keepAlive: true)`로 앱 생명주기 동안 싱글턴 제공; `minglit_data` barrel로 양 앱에 공유<br><br>> **결정 (Q29)**: concrete class 직접 구현 유지 (abstract interface X). 이유 — 단일 백엔드(Supabase) + 통합 테스트 위주(실제 Supabase 연동) 정책 → abstract 도입 시 boilerplate만 ↑ payoff X. **YAGNI 원칙으로 concrete 유지**.
>
> **abstract 도입 트리거** (이 중 하나라도 발생 시 재검토):
> - Offline-first cache 레이어 추가 (DataSource 분리 자연스러워짐)
> - 백엔드 swap 의사결정 (현실적 가능성 낮음)
> - Mock 기반 단위 테스트 정책 채택 (현재 통합 테스트 위주라 N/A)
>
> 향후 누군가 abstract 추가 PR 올리면 위 트리거 하나라도 발생했는지 게이트 발동. |

---

### Settlement (정산)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 정산 |
| **코드명** | `settlement_items` (테이블), `settlements` (레거시 테이블) |
| **기술적 정의** | 이벤트 완료(`completed`) 시 `on_event_completed` 트리거가 자동 생성하는 파트너 수익 정산 레코드. 수수료 계산: PG 3.5% + 플랫폼 5% + VAT 10%. 상태: PENDING → READY(14일) → PROCESSING → COMPLETED / FAILED / HOLD / CANCELED. CAS(낙관적 잠금) 적용. |
| **코드 위치** | `settlement_items` 테이블, `supabase/functions/settlement-transfer/`, `docs/architecture/payment-pipeline.md §6` |
| **관련 용어** | Partner, Refund, Event |
| **비즈니스 의미** | **이벤트 종료 후 14일 보류 → Partner 정산** 모델. 수수료: minglit이 결제액의 **10%** 수취 (가설/draft, 상세 정책은 별도 문서 예정). 무료 이벤트 가능 (수수료 없음). 환불 시 minglit 수수료도 **전액 환불** (Partner도 받은 금액 반환). 14일 hold 이유: 한국 전자상거래법상 청약철회 7일 + 분쟁 처리 여유 buffer. 정확한 정책 근거는 별도 조사 필요 (`<TODO: research/legal-context.md에서 정밀 확인>`). **체크인 기반**: Check-in 된 참가자만 정산 산정에 포함 (Check-in 항목 참조). |

---

### Tag (태그)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 태그 |
| **코드명** | `Tag`, `party_tags`, `ai-extract-tags` (Edge Function) |
| **기술적 정의** | 파티를 분류하는 키워드 레이블. 파티 생성 시 PGMQ `q_tags` 큐를 통해 `ai-extract-tags` Edge Function이 OpenAI로 파티 설명에서 태그를 자동 추출(`source = 'ai'`). PGroonga 검색 인덱스와 별개로 운영. |
| **코드 위치** | `shared/packages/minglit_kit/lib/src/data/models/tag.dart`, `tags` / `party_tags` 테이블, `supabase/functions/ai-extract-tags/` |
| **관련 용어** | Party, Recommendation, Search (PGroonga) |
| **비즈니스 의미** | **이벤트에서 자동 추출되는 분류 키워드**. 추출 대상: Event 설명 (ai-extract-tags edge function). 현재 용도: 인기 태그 노출 (집단 트렌드 surface). 개인화 태그 추천: 현재 없음, 나중에 추가될 수도 있음. 임베딩 vs 태그 분리 원칙: 임베딩 = 개인화 (1:1 사용자→이벤트 매칭), 태그 = 집단 인기 (전체 트렌드 발견). |

---

### Ticket (티켓)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 티켓 |
| **코드명** | `Ticket` |
| **기술적 정의** | 이벤트(Event)에 연결된 참가권. `name`, `price`, `quantity`, `sold_count`, `target_entry_group_ids`, `required_verification_ids`, `status`(on_sale 등)를 보유. 결제 완료 후 `event_participants`에 `ticket_code`와 함께 발권됨. QR 토큰은 Ed25519로 서명 발급(`user-get-ticket-token` EF). |
| **코드 위치** | `shared/packages/minglit_kit/lib/src/data/models/ticket.dart`, `tickets` 테이블 |
| **관련 용어** | TicketTemplate, Application, Event, Check-in |
| **비즈니스 의미** | **EntryGroup 별로 발행되는 입장권**. 한 Event에 여러 Ticket이 존재할 수 있고, 각 Ticket은: 1) `target_entry_group_ids`로 어떤 그룹용인지 명시 (예: 남성 그룹 10장, 여성 그룹 10장 → 자동 성비 쿼터), 2) 가격 차등 가능 (예: 같은 그룹이라도 얼리버드 25,000원 / 정가 35,000원 별도 Ticket으로 발행). 결제 → 발급 → Check-in으로 사용. |

---

### TicketTemplate (티켓 템플릿)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 티켓 템플릿 |
| **코드명** | `TicketTemplate` |
| **기술적 정의** | 파티(Party) 레벨에서 정의하는 티켓 설정 템플릿. 이벤트 생성 시 `Ticket`으로 복사됨. `ticket_templates` 테이블에 저장. `party_id`를 FK로 보유. |
| **코드 위치** | `shared/packages/minglit_kit/lib/src/data/models/ticket_template.dart`, `ticket_templates` 테이블 |
| **관련 용어** | Ticket, Party |
| **비즈니스 의미** | Party 템플릿이 Event를 만들 때 함께 복사되는 티켓 양식. 반복 운영되는 모임에서 매번 가격/쿼터 다시 입력 안 해도 되게 하는 자동화 장치. |

---

### Verification (자격 인증 양식 정의)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 인증 양식 |
| **코드명** | `Verification` (모델), `verifications` (테이블) |
| **기술적 정의** | 파트너가 정의하는 자격 인증 양식. `category`(career / asset / marriage / academic / vehicle / etc), `internal_name`, `display_name`, `form_schema`(JSONB 동적 폼 필드 배열)를 포함. `partner_id`가 null이면 플랫폼 전역(Global) 인증. |
| **코드 위치** | `shared/packages/minglit_kit/lib/src/data/models/verification.dart`, `verifications` 테이블, `docs/architecture/trust-and-verification.md` |
| **관련 용어** | Qualification Verification (Layer 2), VerificationSubmission, Partner |
| **비즈니스 의미** | **Partner가 자유폼으로 Qualification 양식 정의 가능**. 기본 Partner 인증은 minglit이 제공, Partner는 그 위에 자기 모임용 추가 인증을 자유롭게 추가: 입력 형태는 **string** (텍스트 답변, 예: "현재 직장명") OR **이미지/PDF** (재직증명서, 학생증, 명함 등). Partner마다 양식 다름 → 각 Partner의 차별화 도구 + 매칭 신뢰 확보 수단. |

---

### VerificationSubmission (인증 제출)

| 항목 | 내용 |
|------|------|
| **한국어 레이블** | 인증 제출 |
| **코드명** | `VerificationSubmission` |
| **기술적 정의** | 유저가 이벤트 신청 시 파트너에게 제출한 자격 인증 데이터의 스냅샷. `status`(pending / approved / rejected), `snapshot_data`(제출 시점의 데이터 복사본), `admin_comment`를 포함. 승인 시 `on_submission_status_change` 트리거가 `partner_verified_users`를 생성하고 `event_applications.status`를 `approved`로 전환. |
| **코드 위치** | `shared/packages/minglit_kit/lib/src/data/models/verification_submission.dart`, `verification_submissions` 테이블 |
| **관련 용어** | Verification, Application, Qualification Verification |
| **비즈니스 의미** | 사용자가 Partner의 Verification 양식에 답변한 **제출 인스턴스 (스냅샷)**. 양식이 나중에 바뀌어도 기존 제출은 당시 형태 그대로 보존 (감사 추적 + 분쟁 대응). Partner가 검토해서 승인/거부. |

---

*생성 기준: 2026-04-25 / 소스: docs/architecture/*.md, minglit_kit 모델, supabase/migrations/*
