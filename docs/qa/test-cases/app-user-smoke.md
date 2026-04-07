# 유저 앱 (app_user) 전 화면 Smoke 테스트 케이스

> 소스: `docs/ux/information-architecture.md`, `docs/ux/menu-structure.md`
>
> 목적: 모든 화면이 크래시 없이 진입 가능한지 검증. 인증 상태별 접근 제어 포함.

---

## 1. 인증 상태 정의

| 상태 코드 | 설명 | 조건 |
|-----------|------|------|
| `GUEST` | 비로그인 | 세션 없음 |
| `AUTH` | 로그인 완료 | Supabase 세션 있음, 본인인증 미완료 |
| `VERIFIED` | 본인인증 완료 | 세션 + identity_verified = true |

---

## 2. 화면별 진입 테스트 매트릭스

### 2.1 공개 화면 (인증 불필요)

| # | 화면 | 경로 | Page 클래스 | GUEST | AUTH | VERIFIED | 비고 |
|---|------|------|------------|-------|------|----------|------|
| U-S01 | 홈 | `/` | `HomePage` | OK | OK | OK | 앱 진입점 |
| U-S02 | 큐레이션 목록 | `/curation` | `PartyCurationPage` | OK | OK | OK | 홈 → 큐레이션 |
| U-S03 | 검색 | `/search` | `SearchPage` | OK | OK | OK | |
| U-S04 | 이벤트 상세 | `/events/:eventId` | `EventDetailPage` | OK | OK | OK | 유효한 eventId 필요 |
| U-S05 | 파트너 상세 | `/partners/:partnerId` | `PartnerDetailPage` | OK | OK | OK | 유효한 partnerId 필요 |
| U-S06 | 파트너 이벤트 목록 | `/partners/:partnerId/events` | `PartnerEventsPage` | OK | OK | OK | |
| U-S07 | 로그인 | `/login` | `LoginPage` | OK | → `/` | → `/` | 이미 로그인 시 홈으로 리다이렉트 |
| U-S08 | OAuth 콜백 | `/auth/callback` | `AuthCallbackPage` | OK | OK | OK | OAuth 플로우 전용 |

### 2.2 보호된 화면 (로그인 필수)

| # | 화면 | 경로 | Page 클래스 | GUEST | AUTH | VERIFIED | 비고 |
|---|------|------|------------|-------|------|----------|------|
| U-S09 | 마이페이지 | `/my` | `MyPage` | → `/login` | OK | OK | prefix `/my` 보호 |
| U-S10 | 개인정보 설정 | `/my/privacy` | `PrivacyPage` | → `/login` | OK | OK | |
| U-S11 | 차단 파트너 관리 | `/my/blocked-partners` | `BlockedPartnersPage` | → `/login` | OK | OK | |
| U-S12 | 알림 설정 | `/my/notification-settings` | `NotificationSettingsScreen` | → `/login` | OK | OK | |
| U-S13 | 구매 내역 | `/purchase-history` | `PurchaseHistoryPage` | → `/login` | OK | OK | prefix `/purchase-history` 보호 |
| U-S14 | 알림 센터 | `/notifications` | `NotificationListScreen` | → `/login` | OK | OK | |
| U-S15 | 본인인증 | `/certification` | `IdentityVerificationScreen` | → `/login` | OK | OK | prefix `/certification` 보호 |

### 2.3 보호된 화면 (로그인 + 추가 조건)

| # | 화면 | 경로 | Page 클래스 | GUEST | AUTH | VERIFIED | 비고 |
|---|------|------|------------|-------|------|----------|------|
| U-S16 | 이벤트 신청 위저드 | `/events/:eventId/apply` | `EventApplicationWizardPage` | → `/login` | OK | OK | suffix `/apply` 보호. 위저드 내부에서 본인인증 스텝 포함 |

### 2.4 개발 전용 화면 (Dev Only)

| # | 화면 | 경로 | Page 클래스 | GUEST | AUTH | VERIFIED | 비고 |
|---|------|------|------------|-------|------|----------|------|
| U-S17 | 개발 도구 | `/dev` | `UserDevMap` | OK | OK | OK | dev flavor만 접근 가능 |
| U-S18 | 유저 전환 | `/dev/switch` | `DevUserSwitchScreen` | OK | OK | OK | dev flavor만 접근 가능 |

---

## 3. 리다이렉트 검증 케이스

| # | 시나리오 | 입력 | 기대 결과 |
|---|----------|------|-----------|
| U-R01 | 비로그인 → 보호 화면 | GUEST가 `/my` 접근 | `/login?from=/my` 로 리다이렉트 |
| U-R02 | 로그인 후 복귀 | `/login?from=/my`에서 로그인 성공 | `/my`로 이동 |
| U-R03 | 로그인 상태로 `/login` 접근 | AUTH가 `/login` 접근 | `/` 로 리다이렉트 |
| U-R04 | 레거시 경로 | `/explore/...` 접근 | `/` 로 리다이렉트 |
| U-R05 | 비로그인 → 이벤트 신청 | GUEST가 `/events/123/apply` 접근 | `/login?from=/events/123/apply` |

---

## 4. 파라미터별 엣지 케이스

| # | 화면 | 시나리오 | 기대 결과 |
|---|------|----------|-----------|
| U-E01 | 이벤트 상세 | 존재하지 않는 eventId | 에러 화면 또는 홈으로 이동 |
| U-E02 | 파트너 상세 | 존재하지 않는 partnerId | 에러 화면 또는 홈으로 이동 |
| U-E03 | 이벤트 신청 | 이미 신청한 이벤트 | 중복 신청 방지 처리 |
| U-E04 | 이벤트 신청 | 마감된 이벤트 | 신청 불가 안내 |
| U-E05 | 구매 내역 | 구매 이력 없음 | 빈 상태 화면 |
| U-E06 | 차단 파트너 | 차단 목록 비어있음 | 빈 상태 화면 |
| U-E07 | 알림 센터 | 알림 없음 | 빈 상태 화면 |

---

## 5. 화면별 액션 매트릭스

### 5.1 홈 (HomePage)

| 액션 | 기대 결과 | 에러 시나리오 |
|------|-----------|-------------|
| 이벤트 카드 탭 | `/events/:eventId`로 이동 | - |
| 큐레이션 섹션 탭 | `/curation`으로 이동 | - |
| 검색 아이콘 탭 | `/search`로 이동 | - |
| 마이페이지 아이콘 탭 | `/my`로 이동 (GUEST → 로그인) | - |
| 알림 아이콘 탭 | `/notifications`로 이동 | - |
| 풀투리프레시 | 홈 데이터 갱신 | 네트워크 오류 → 에러 표시 |

### 5.2 검색 (SearchPage)

| 액션 | 기대 결과 | 에러 시나리오 |
|------|-----------|-------------|
| 검색어 입력 + 검색 | 검색 결과 표시 | 결과 없음 → 빈 상태 |
| 검색 결과 이벤트 탭 | `/events/:eventId`로 이동 | - |
| 검색 결과 파트너 탭 | `/partners/:partnerId`로 이동 | - |
| 필터 적용 | 필터된 결과 표시 | - |

### 5.3 이벤트 상세 (EventDetailPage)

| 액션 | 기대 결과 | 에러 시나리오 |
|------|-----------|-------------|
| 신청 버튼 탭 | `/events/:eventId/apply`로 이동 | GUEST → 로그인 리다이렉트 |
| 파트너 프로필 탭 | `/partners/:partnerId`로 이동 | - |
| 공유 버튼 | 공유 시트 표시 | - |
| 뒤로가기 | 이전 화면으로 복귀 | - |

### 5.4 이벤트 신청 위저드 (EventApplicationWizardPage)

| 액션 | 기대 결과 | 에러 시나리오 |
|------|-----------|-------------|
| 티켓 선택 | 선택된 티켓 표시 + 다음 스텝 | 매진 → 선택 불가 |
| 본인인증 스텝 | 인증 화면 → 인증 완료 | 인증 실패 → 재시도 안내 |
| 결제 스텝 | PG 결제 진행 | 결제 실패 → 에러 메시지 |
| 신청 완료 | 완료 화면 표시 | - |
| 뒤로가기 (중간 스텝) | 이전 스텝으로 복귀 | - |
| 위저드 이탈 | 확인 다이얼로그 표시 | - |

### 5.5 마이페이지 (MyPage)

| 액션 | 기대 결과 | 에러 시나리오 |
|------|-----------|-------------|
| 구매 내역 탭 | `/purchase-history`로 이동 | - |
| 개인정보 설정 탭 | `/my/privacy`로 이동 | - |
| 차단 파트너 탭 | `/my/blocked-partners`로 이동 | - |
| 알림 설정 탭 | `/my/notification-settings`로 이동 | - |
| 로그아웃 | 로그아웃 → 홈으로 이동 | - |

### 5.6 구매 내역 (PurchaseHistoryPage)

| 액션 | 기대 결과 | 에러 시나리오 |
|------|-----------|-------------|
| 구매 항목 탭 | 상세 정보 표시 | - |
| 환불 신청 | 환불 프로세스 진입 | 환불 기간 초과 → 불가 안내 |
| 풀투리프레시 | 목록 갱신 | 네트워크 오류 |

### 5.7 파트너 상세 (PartnerDetailPage)

| 액션 | 기대 결과 | 에러 시나리오 |
|------|-----------|-------------|
| 이벤트 목록 보기 | `/partners/:partnerId/events`로 이동 | - |
| 이벤트 카드 탭 | `/events/:eventId`로 이동 | - |
| 차단하기 | 차단 확인 다이얼로그 → 차단 처리 | - |

### 5.8 개인정보 설정 (PrivacyPage)

| 액션 | 기대 결과 | 에러 시나리오 |
|------|-----------|-------------|
| 계정 삭제 | 삭제 확인 플로우 진입 | - |
| 개인정보 수정 | 수정 완료 → 저장 | 유효성 검사 실패 |

### 5.9 알림 센터 (NotificationListScreen)

| 액션 | 기대 결과 | 에러 시나리오 |
|------|-----------|-------------|
| 알림 항목 탭 | 관련 화면으로 딥링크 이동 | 대상 화면 없음 → 에러 처리 |
| 알림 읽음 처리 | 읽음 상태 갱신 | - |
| 풀투리프레시 | 알림 목록 갱신 | 네트워크 오류 |

### 5.10 알림 설정 (NotificationSettingsScreen)

| 액션 | 기대 결과 | 에러 시나리오 |
|------|-----------|-------------|
| 토글 변경 | 설정 저장 | 저장 실패 → 에러 메시지 |

---

## 6. 총 테스트 케이스 수

| 구분 | 수량 |
|------|------|
| 화면 진입 Smoke | 18 |
| 리다이렉트 검증 | 5 |
| 파라미터 엣지 케이스 | 7 |
| 화면별 액션 | 38 |
| **합계** | **68** |
