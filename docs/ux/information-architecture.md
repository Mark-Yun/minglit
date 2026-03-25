# Information Architecture

> 소스: GoRouter 라우트 정의에서 추출. 코드와 1:1 대응.
>
> - `apps/app_user/lib/src/routing/app_routes.dart`
> - `apps/app_partner/lib/src/routing/app_routes.dart`
> - `apps/app_user/lib/src/routing/app_router.dart` (redirect/guard)
> - `apps/app_partner/lib/src/routing/app_router.dart` (redirect/guard)

---

## 1. 유저 앱 (app_user) 화면 계층

### 1.1 BottomNav Shell (2탭)

```
UserShellRoute (StatefulShellRoute)
├── [홈] HomeBranch
│   └── HomeRoute                /                 → HomePage
│       └── EventCurationRoute   /curation          → PartyCurationPage
└── [마이] MyPageBranch
    └── MyPageRoute              /my                → MyPage
```

### 1.2 Top-Level Routes (Shell 외부)

| Route | Path | Page | 비고 |
|-------|------|------|------|
| `LoginRoute` | `/login` | `LoginPage` | `?from=` 쿼리로 원래 경로 보존 |
| `AuthCallbackRoute` | `/auth/callback` | `AuthCallbackPage` | OAuth 콜백 |
| `CertificationRoute` | `/certification` | `IdentityVerificationScreen` | 본인인증 (보호) |
| `EventDetailRoute` | `/events/:eventId` | `EventDetailPage` | 이벤트 상세 |
| `EventApplicationRoute` | `/events/:eventId/apply` | `EventApplicationWizardPage` | 신청 위저드 (보호) |
| `PartnerDetailRoute` | `/partners/:partnerId` | `PartnerDetailPage` | 파트너(업체) 상세 |
| `SearchRoute` | `/search` | `SearchPage` | 검색 |
| `PurchaseHistoryRoute` | `/purchase-history` | `PurchaseHistoryPage` | 구매 내역 (보호) |
| `NotificationCenterRoute` | `/notifications` | `NotificationListScreen` | 알림 센터 |
| `NotificationSettingsRoute` | `/my/notification-settings` | `NotificationSettingsScreen` | 알림 설정 (보호) |
| `DevRoute` | `/dev` | `UserDevMap` | 개발 도구 (dev only) |
| `DevUserSwitchRoute` | `/dev/switch` | `DevUserSwitchScreen` | 테스트 유저 전환 (dev only) |

### 1.3 핵심 유저 플로우

```
홈 → 이벤트 상세 → 신청 위저드 → (결제 스텝) → 완료
 /     /events/:id    /events/:id/apply
```

```
홈 → 검색 → 이벤트 상세
 /    /search   /events/:id
```

```
마이페이지 → 구매 내역
   /my         /purchase-history
```

---

## 2. 파트너 앱 (app_partner) 화면 계층

### 2.1 BottomNav Shell (4탭)

```
PartnerShellRoute (StatefulShellRoute)
├── [홈] HomeBranch
│   └── HomeRoute                    /                          → PartnerHomePage
│       ├── ApplicationListRoute     /applications              → PartnerApplicationListPage
│       │   └── ApplicationDetailRoute /applications/:applicationId → PartnerApplicationDetailPage
│       └── LocationGuideRoute       /guide/location            → LocationGuidePage
│
├── [파티관리] PartyBranch
│   └── PartyListRoute              /parties                   → PartyListPage
│       ├── PartyCreateRoute        /parties/create            → PartyCreateWizardPage
│       └── PartyDetailRoute        /parties/:partyId          → PartyDetailPage
│           ├── PartyEditRoute      /parties/:partyId/edit     → PartyCreateWizardPage (편집)
│           ├── PartyTicketEditRoute /parties/:partyId/tickets/:ticketId/edit → TicketEditPage
│           ├── EventCreateRoute    /parties/:partyId/events/create → EventCreatePage
│           └── EventDetailRoute    /parties/:partyId/events/:eventId → EventDetailPage
│               ├── TicketCreateRoute /parties/:partyId/events/:eventId/tickets/create → TicketCreatePage
│               └── TicketEditRoute   /parties/:partyId/events/:eventId/tickets/:ticketId/edit → TicketEditPage
│
├── [수익관리] SettlementBranch
│   └── SettlementRoute             /settlement                → SettlementPage
│
└── [설정] MoreBranch
    └── MoreRoute                   /more                      → MorePage
        ├── VerificationManageRoute /more/verifications/manage  → VerificationManagePage
        ├── CreateVerificationRoute /more/verifications/create  → CreateVerificationPage
        └── MemberListRoute         /more/partners/:partnerId/members → PartnerMemberListPage
            └── MemberPermissionRoute /more/partners/:partnerId/members/:targetUserId/permission → PartnerMemberPermissionPage
```

### 2.2 Top-Level Routes (Shell 외부)

| Route | Path | Page | 비고 |
|-------|------|------|------|
| `LoginRoute` | `/login` | `PartnerLoginPage` | 로그인 |
| `PartnerApplyRoute` | `/apply` | `PartnerApplyPage` | 파트너 신청 위저드 |
| `PartnerApplyStatusRoute` | `/apply/status` | `PartnerApplyStatusPage` | 심사 상태 확인 |
| `NotificationCenterRoute` | `/notifications` | `NotificationListScreen` | 알림 센터 |
| `DevMapRoute` | `/dev` | `PartnerDevMap` | 개발 도구 (dev only) |
| `DevUserSwitchRoute` | `/dev/user-switch` | `DevUserSwitchScreen` | 테스트 유저 전환 (dev only) |

### 2.3 핵심 파트너 플로우

```
파티 목록 → 파티 생성 위저드
/parties     /parties/create

파티 목록 → 파티 상세 → 이벤트 생성 → 이벤트 상세 → 티켓 생성
/parties   /parties/:id  /parties/:id/events/create  /parties/:id/events/:eid  .../tickets/create

수익관리 (정산)
/settlement
```

---

## 3. 인증 흐름

### 3.1 유저 앱 인증

```
게스트 (비로그인)
  │
  ├── 공개 화면 자유 열람: /, /events/:id, /search, /partners/:id
  │
  ├── 보호된 화면 접근 시 → /login?from=<원래경로>
  │   └── 로그인 성공 → from 경로로 리다이렉트
  │
  └── 본인인증 필요 시 → /certification
      └── IdentityVerificationScreen
```

**Redirect 로직** (`app_router.dart`):
1. 이미 로그인 + `/login` 접근 -> `from` 파라미터 또는 `/` 로 리다이렉트
2. 비로그인 + 보호된 경로 접근 -> `/login?from=<path>` 로 리다이렉트
3. `/explore` prefix -> `/` 로 리다이렉트 (하위호환)
4. `/dev` prefix -> 인증 없이 허용

**AuthGuard 위젯** (`auth_guard.dart`):
- GoRouter redirect 외에 위젯 레벨 가드도 사용
- 비로그인 시 "로그인이 필요합니다" 화면 + 로그인 버튼 표시
- push 기반이라 뒤로가기가 자연스러움

### 3.2 파트너 앱 인증

```
비로그인
  │
  ├── /login (유일한 공개 화면)
  │
  └── 로그인 성공
      │
      ├── 파트너 미등록 (needsApplication / draftInProgress)
      │   └── /apply (파트너 신청 위저드)
      │
      ├── 심사 중 (pendingReview / needsCorrection)
      │   └── /apply/status (심사 상태 페이지)
      │
      └── 파트너 등록 완료 (hasPartner)
          └── / (대시보드 홈)
```

**Redirect 로직** (`app_router.dart`):
1. 비로그인 + `/login` 아님 -> `/login`
2. 로그인 + `/login` -> `/`
3. 로그인 + onboarding 미완료 -> `/apply` 또는 `/apply/status`
4. 로그인 + onboarding 완료 + `/apply` 접근 -> `/`
5. `/dev` prefix -> 인증 없이 허용

---

## 4. 딥링크 매핑

### 4.1 설정

| 플랫폼 | 도메인 | 설정 파일 |
|---------|--------|-----------|
| Android (App Links) | `app.minglit.com` | `android/app/src/main/AndroidManifest.xml` |
| iOS (Universal Links) | `app.minglit.com`, `dev.app.minglit.com` | `ios/Runner/Runner.entitlements` |
| Web (AASA) | `app.minglit.com` | `web/.well-known/apple-app-site-association` |

### 4.2 지원 경로

| 딥링크 URL | 앱 내 라우트 | 대상 화면 |
|------------|-------------|-----------|
| `https://app.minglit.com/events/{eventId}` | `/events/:eventId` | 이벤트 상세 |

### 4.3 OAuth 콜백 커스텀 스킴

| 스킴 | 용도 |
|------|------|
| `com.minglit.app_user://callback` | Supabase OAuth 인증 콜백 |

---

## 5. 보호된 라우트 목록

### 5.1 유저 앱

GoRouter redirect에서 prefix/suffix 매칭으로 보호:

| 보호 조건 | 경로 | 설명 |
|-----------|------|------|
| prefix `/my` | `/my`, `/my/notification-settings` | 마이페이지 전체 |
| prefix `/tickets/my` | `/tickets/my/*` | 내 티켓 목록 |
| prefix `/payment` | `/payment/*` | 결제 관련 |
| prefix `/purchase-history` | `/purchase-history` | 구매 내역 |
| prefix `/certification` | `/certification` | 본인인증 |
| suffix `/apply` | `/events/:eventId/apply` | 이벤트 신청 |

### 5.2 파트너 앱

파트너 앱은 **전체가 보호됨** (로그인 필수):
- `/login` 과 `/dev/*` 만 예외
- 로그인 후에도 onboarding 상태에 따라 `/apply` 또는 `/apply/status`로 리다이렉트
