# Menu Structure (메뉴 구조도)

> 소스: GoRouter 라우트 정의 + Scaffold BottomNav에서 추출.
>
> - `apps/app_user/lib/src/routing/app_routes.dart`
> - `apps/app_user/lib/src/ui/shell/user_scaffold.dart`
> - `apps/app_partner/lib/src/routing/app_routes.dart`
> - `apps/app_partner/lib/src/ui/shell/partner_scaffold.dart`

---

## 1. 유저 앱 (app_user)

### 1.1 BottomNav (2탭)

| # | 아이콘 | 라벨 | 경로 | 소스 파일 |
|---|--------|------|------|-----------|
| 1 | `home` | 홈 | `/` | `user_scaffold.dart` |
| 2 | `person` | 마이 | `/my` | `user_scaffold.dart` |

> BottomNav 정의: `apps/app_user/lib/src/ui/shell/user_scaffold.dart`
> - Blur 배경 + 스크롤 시 자동 숨김/표시 (`NavVisibilityProvider`)

### 1.2 탑레벨 라우트 트리

```
[BottomNav Shell] ─ UserScaffold
│
├── 홈 탭 (/)
│   ├── HomePage                      apps/app_user/lib/src/features/home/home_page.dart
│   └── 큐레이션 목록 (/curation)
│       └── PartyCurationPage         apps/app_user/lib/src/features/party/party_curation_page.dart
│
└── 마이 탭 (/my)
    └── MyPage                        apps/app_user/lib/src/features/home/my_page.dart

[Shell 외부 독립 화면]
│
├── 로그인 (/login)
│   └── LoginPage                     apps/app_user/lib/src/features/auth/login_page.dart
│
├── OAuth 콜백 (/auth/callback)
│   └── AuthCallbackPage              apps/app_user/lib/src/features/auth/ui/auth_callback_page.dart
│
├── 본인인증 (/certification)
│   └── IdentityVerificationScreen    (minglit_kit)
│
├── 검색 (/search)
│   └── SearchPage                    apps/app_user/lib/src/features/search/search_page.dart
│
├── 이벤트 상세 (/events/:eventId)
│   └── EventDetailPage               apps/app_user/lib/src/features/event/detail/event_detail_page.dart
│
├── 이벤트 신청 (/events/:eventId/apply)
│   └── EventApplicationWizardPage    apps/app_user/lib/src/features/event/admission/event_application_wizard_page.dart
│
├── 파트너 상세 (/partners/:partnerId)
│   └── PartnerDetailPage             apps/app_user/lib/src/features/partner/detail/partner_detail_page.dart
│
├── 구매 내역 (/purchase-history)
│   └── PurchaseHistoryPage           apps/app_user/lib/src/features/payment/ui/purchase_history_page.dart
│
├── 알림 센터 (/notifications)
│   └── NotificationListScreen        (minglit_kit)
│
├── 알림 설정 (/my/notification-settings)
│   └── NotificationSettingsScreen    (minglit_kit)
│
└── [Dev Only]
    ├── 개발 도구 (/dev)
    │   └── UserDevMap                apps/app_user/lib/src/features/dev/user_dev_map.dart
    └── 유저 전환 (/dev/switch)
        └── DevUserSwitchScreen       (minglit_kit)
```

### 1.3 피처 디렉토리 구조

```
apps/app_user/lib/src/features/
├── auth/           로그인, OAuth 콜백, AuthGuard
├── dev/            개발 도구 (dev only)
├── event/          이벤트 상세, 신청 위저드, 매칭 투표
│   ├── admission/  신청 위저드 (결제, 본인인증 스텝 포함)
│   ├── detail/     이벤트 상세 화면 + 위젯
│   ├── logic/      이벤트 컨트롤러, 코디네이터
│   └── matching/   매칭 투표
├── explore/        탐색 필터, 상태 관리
├── home/           홈, 마이페이지
├── partner/        파트너 상세 (detail/)
├── party/          파티 큐레이션 페이지
├── payment/        결제, 구매 내역
│   ├── logic/      결제 코디네이터, 구매 내역 컨트롤러
│   └── ui/         구매 내역 페이지, 결제 성공 화면
├── search/         검색 페이지
├── settings/       차단 파트너 관리
└── ticket/         티켓 QR, 티켓 선택
    ├── data/       티켓 월렛 리포지토리
    ├── logic/      티켓 코디네이터
    └── ui/         티켓 QR 화면, 선택 시트
```

---

## 2. 파트너 앱 (app_partner)

### 2.1 BottomNav (4탭)

| # | 아이콘 | 라벨 | 경로 | 소스 파일 |
|---|--------|------|------|-----------|
| 1 | `home` | 홈 | `/` | `partner_scaffold.dart` |
| 2 | `celebration` | 파티관리 | `/parties` | `partner_scaffold.dart` |
| 3 | `attach_money` | 수익관리 | `/settlement` | `partner_scaffold.dart` |
| 4 | `settings` | 설정 | `/more` | `partner_scaffold.dart` |

> BottomNav 정의: `apps/app_partner/lib/src/ui/shell/partner_scaffold.dart`

### 2.2 전체 라우트 트리

```
[BottomNav Shell] ─ PartnerScaffold
│
├── 홈 탭 (/)
│   ├── PartnerHomePage                    apps/app_partner/lib/src/features/home/partner_home_page.dart
│   ├── 파트너 신청 목록 (/applications)
│   │   ├── PartnerApplicationListPage     apps/app_partner/lib/src/features/admin/partner_application_list_page.dart
│   │   └── 신청 상세 (/applications/:applicationId)
│   │       └── PartnerApplicationDetailPage apps/app_partner/lib/src/features/admin/partner_application_detail_page.dart
│   └── 장소 가이드 (/guide/location)
│       └── LocationGuidePage              apps/app_partner/lib/src/features/home/guide/location_guide_page.dart
│
├── 파티관리 탭 (/parties)
│   ├── PartyListPage                      apps/app_partner/lib/src/features/party/list/party_list_page.dart
│   ├── 파티 생성 (/parties/create)
│   │   └── PartyCreateWizardPage          apps/app_partner/lib/src/features/party/create/party_create_wizard_page.dart
│   └── 파티 상세 (/parties/:partyId)
│       ├── PartyDetailPage                apps/app_partner/lib/src/features/party/detail/party_detail_page.dart
│       ├── 파티 편집 (/parties/:partyId/edit)
│       │   └── PartyCreateWizardPage      apps/app_partner/lib/src/features/party/create/party_create_wizard_page.dart
│       ├── 파티 티켓 편집 (/parties/:partyId/tickets/:ticketId/edit)
│       │   └── TicketEditPage             apps/app_partner/lib/src/features/ticket/edit/ticket_edit_page.dart
│       ├── 이벤트 생성 (/parties/:partyId/events/create)
│       │   └── EventCreatePage            apps/app_partner/lib/src/features/party/event/create/event_create_page.dart
│       └── 이벤트 상세 (/parties/:partyId/events/:eventId)
│           ├── EventDetailPage            apps/app_partner/lib/src/features/party/event/detail/event_detail_page.dart
│           ├── 티켓 생성 (.../tickets/create)
│           │   └── TicketCreatePage       apps/app_partner/lib/src/features/ticket/create/ticket_create_page.dart
│           └── 티켓 편집 (.../tickets/:ticketId/edit)
│               └── TicketEditPage         apps/app_partner/lib/src/features/ticket/edit/ticket_edit_page.dart
│
├── 수익관리 탭 (/settlement)
│   └── SettlementPage                     apps/app_partner/lib/src/features/settlement/settlement_page.dart
│
└── 설정 탭 (/more)
    ├── MorePage                           apps/app_partner/lib/src/features/more/more_page.dart
    ├── 인증 관리 (/more/verifications/manage)
    │   └── VerificationManagePage         apps/app_partner/lib/src/features/verification/manage/verification_manage_page.dart
    ├── 인증 생성 (/more/verifications/create)
    │   └── CreateVerificationPage         apps/app_partner/lib/src/features/verification/create/create_verification_page.dart
    └── 멤버 관리 (/more/partners/:partnerId/members)
        ├── PartnerMemberListPage          apps/app_partner/lib/src/features/member/partner_member_list_page.dart
        └── 멤버 권한 (.../members/:targetUserId/permission)
            └── PartnerMemberPermissionPage apps/app_partner/lib/src/features/member/partner_member_permission_page.dart

[Shell 외부 독립 화면]
│
├── 로그인 (/login)
│   └── PartnerLoginPage                   apps/app_partner/lib/src/features/auth/partner_login_page.dart
│
├── 파트너 신청 (/apply)
│   └── PartnerApplyPage                   apps/app_partner/lib/src/features/onboarding/partner_apply_page.dart
│
├── 신청 상태 (/apply/status)
│   └── PartnerApplyStatusPage             apps/app_partner/lib/src/features/onboarding/partner_apply_status_page.dart
│
├── 알림 센터 (/notifications)
│   └── NotificationListScreen             (minglit_kit)
│
└── [Dev Only]
    ├── 개발 도구 (/dev)
    │   └── PartnerDevMap                  apps/app_partner/lib/src/features/dev/partner_dev_map.dart
    └── 유저 전환 (/dev/user-switch)
        └── DevUserSwitchScreen            (minglit_kit)
```

### 2.3 피처 디렉토리 구조

```
apps/app_partner/lib/src/features/
├── admin/          파트너 신청 관리 (어드민)
├── auth/           로그인
├── checkin/        QR 체크인
├── dev/            개발 도구 (dev only)
├── home/           대시보드 홈
│   ├── guide/      장소 가이드
│   └── widgets/    대시보드 카드들 (매출 요약, 다가오는 이벤트 등)
├── member/         파트너 멤버 관리 (목록, 권한)
├── more/           설정/더보기
├── onboarding/     파트너 신청 위저드
│   ├── steps/      Step 1~5 (기본정보, 사업자, 연락처/정산, 서류, 검토)
│   └── widgets/    주소 검색 다이얼로그
├── party/          파티 관리 (핵심 기능)
│   ├── create/     파티 생성/편집 위저드
│   │   └── steps/  Step 1~6 (기본, 장소, 정원/연락처, 입장규칙, 티켓, 검토)
│   ├── detail/     파티 상세 (탭 구조: 정보, 운영, 이벤트, 규칙)
│   │   └── tabs/
│   ├── event/      이벤트 CRUD
│   │   ├── create/ 이벤트 생성
│   │   ├── detail/ 이벤트 상세 (신청자 관리)
│   │   └── widgets/ 이벤트 관련 위젯
│   ├── list/       파티 목록
│   ├── matching/   매칭 설정
│   ├── ticket/     파티 티켓 템플릿 관리
│   └── widgets/    파티 공통 위젯 (상태 편집, 이미지 에디터 등)
├── qr/             QR 스캐너
├── settlement/     정산/수익 관리
├── ticket/         이벤트 티켓 CRUD
│   ├── create/
│   ├── edit/
│   ├── logic/
│   └── widgets/
└── verification/   인증 (자격 검증) 관리
    ├── create/     인증 생성
    ├── manage/     인증 관리
    └── review/     인증 심사
```
