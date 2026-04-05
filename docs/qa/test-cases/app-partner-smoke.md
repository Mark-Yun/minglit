# 파트너 앱 (app_partner) 전 화면 Smoke 테스트 케이스

> 소스: `docs/ux/information-architecture.md`, `docs/ux/menu-structure.md`
>
> 목적: 모든 화면이 크래시 없이 진입 가능한지 검증. 인증/온보딩 상태별 접근 제어 포함.

---

## 1. 인증/온보딩 상태 정의

파트너 앱은 **전체가 보호됨** (로그인 필수). `/login`과 `/dev/*`만 예외.

| 상태 코드 | 설명 | 조건 |
|-----------|------|------|
| `GUEST` | 비로그인 | 세션 없음 |
| `NEEDS_APP` | 로그인 + 파트너 미등록 | needsApplication / draftInProgress |
| `PENDING` | 로그인 + 심사 중 | pendingReview / needsCorrection |
| `PARTNER` | 로그인 + 파트너 등록 완료 | hasPartner |

---

## 2. 화면별 진입 테스트 매트릭스

### 2.1 Shell 외부 — 인증/온보딩 화면

| # | 화면 | 경로 | Page 클래스 | GUEST | NEEDS_APP | PENDING | PARTNER | 비고 |
|---|------|------|------------|-------|-----------|---------|---------|------|
| P-S01 | 로그인 | `/login` | `PartnerLoginPage` | OK | → `/welcome` | → `/apply/status` | → `/` | 상태별 리다이렉트 |
| P-S02 | 웰컴 | `/welcome` | `PartnerWelcomePage` | → `/login` | OK | → `/apply/status` | → `/` | 파트너 미등록만 |
| P-S03 | 파트너 신청 | `/apply` | `PartnerApplyPage` | → `/login` | OK | OK | → `/` | 온보딩 위저드 |
| P-S04 | 신청 상태 | `/apply/status` | `PartnerApplyStatusPage` | → `/login` | → `/welcome` | OK | → `/` | 심사 상태 확인 |

### 2.2 BottomNav Shell — 홈 탭

| # | 화면 | 경로 | Page 클래스 | GUEST | NEEDS_APP | PENDING | PARTNER | 비고 |
|---|------|------|------------|-------|-----------|---------|---------|------|
| P-S05 | 홈 (대시보드) | `/` | `PartnerHomePage` | → `/login` | → `/welcome` | → `/apply/status` | OK | 5탭 쉘 내부 |
| P-S06 | 장소 가이드 | `/guide/location` | `LocationGuidePage` | → `/login` | → `/welcome` | → `/apply/status` | OK | 홈 → 가이드 |

### 2.3 BottomNav Shell — 신청관리 탭

| # | 화면 | 경로 | Page 클래스 | GUEST | NEEDS_APP | PENDING | PARTNER | 비고 |
|---|------|------|------------|-------|-----------|---------|---------|------|
| P-S07 | 신청 관리 목록 | `/applications` | `EventApplicationManagePage` | → `/login` | → `/welcome` | → `/apply/status` | OK | |
| P-S08 | 신청 상세 | `/applications/:applicationId` | `PartnerApplicationDetailPage` | → `/login` | → `/welcome` | → `/apply/status` | OK | 유효한 applicationId 필요 |

### 2.4 BottomNav Shell — 체크인 탭

| # | 화면 | 경로 | Page 클래스 | GUEST | NEEDS_APP | PENDING | PARTNER | 비고 |
|---|------|------|------------|-------|-----------|---------|---------|------|
| P-S09 | 체크인 | `/checkin` | `CheckinPlaceholderPage` | → `/login` | → `/welcome` | → `/apply/status` | OK | 플레이스홀더 |

### 2.5 BottomNav Shell — 정산 탭

| # | 화면 | 경로 | Page 클래스 | GUEST | NEEDS_APP | PENDING | PARTNER | 비고 |
|---|------|------|------------|-------|-----------|---------|---------|------|
| P-S10 | 정산 | `/settlement` | `SettlementPage` | → `/login` | → `/welcome` | → `/apply/status` | OK | |
| P-S11 | 계좌 관리 | `/settlement/bank-account` | `BankAccountPage` | → `/login` | → `/welcome` | → `/apply/status` | OK | |
| P-S12 | 정산 상세 | `/settlement/:id` | `SettlementDetailPage` | → `/login` | → `/welcome` | → `/apply/status` | OK | 유효한 settlementId 필요 |

### 2.6 BottomNav Shell — 더보기 탭

| # | 화면 | 경로 | Page 클래스 | GUEST | NEEDS_APP | PENDING | PARTNER | 비고 |
|---|------|------|------------|-------|-----------|---------|---------|------|
| P-S13 | 더보기 | `/more` | `MorePage` | → `/login` | → `/welcome` | → `/apply/status` | OK | 설정 메뉴 |
| P-S14 | 파티 목록 | `/more/parties` | `PartyListPage` | → `/login` | → `/welcome` | → `/apply/status` | OK | |
| P-S15 | 파티 생성 | `/more/parties/create` | `PartyCreateWizardPage` | → `/login` | → `/welcome` | → `/apply/status` | OK | 위저드 |
| P-S16 | 파티 상세 | `/more/parties/:partyId` | `PartyDetailPage` | → `/login` | → `/welcome` | → `/apply/status` | OK | 유효한 partyId 필요 |
| P-S17 | 파티 편집 | `/more/parties/:partyId/edit` | `PartyCreateWizardPage` | → `/login` | → `/welcome` | → `/apply/status` | OK | 편집 모드 |
| P-S18 | 파티 티켓 편집 | `/more/parties/:partyId/tickets/:ticketId/edit` | `TicketEditPage` | → `/login` | → `/welcome` | → `/apply/status` | OK | |
| P-S19 | 이벤트 생성 | `/more/parties/:partyId/events/create` | `EventCreatePage` | → `/login` | → `/welcome` | → `/apply/status` | OK | |
| P-S20 | 이벤트 상세 | `/more/parties/:partyId/events/:eventId` | `EventDetailPage` | → `/login` | → `/welcome` | → `/apply/status` | OK | |
| P-S21 | 티켓 생성 | `.../events/:eventId/tickets/create` | `TicketCreatePage` | → `/login` | → `/welcome` | → `/apply/status` | OK | |
| P-S22 | 티켓 편집 | `.../events/:eventId/tickets/:ticketId/edit` | `TicketEditPage` | → `/login` | → `/welcome` | → `/apply/status` | OK | |
| P-S23 | 인증 관리 | `/more/verifications/manage` | `VerificationManagePage` | → `/login` | → `/welcome` | → `/apply/status` | OK | |
| P-S24 | 인증 생성 | `/more/verifications/create` | `CreateVerificationPage` | → `/login` | → `/welcome` | → `/apply/status` | OK | |
| P-S25 | 알림 설정 | `/more/notification-settings` | `NotificationSettingsScreen` | → `/login` | → `/welcome` | → `/apply/status` | OK | |
| P-S26 | 멤버 목록 | `/more/partners/:partnerId/members` | `PartnerMemberListPage` | → `/login` | → `/welcome` | → `/apply/status` | OK | |
| P-S27 | 멤버 권한 | `.../members/:targetUserId/permission` | `PartnerMemberPermissionPage` | → `/login` | → `/welcome` | → `/apply/status` | OK | |

### 2.7 기타

| # | 화면 | 경로 | Page 클래스 | GUEST | NEEDS_APP | PENDING | PARTNER | 비고 |
|---|------|------|------------|-------|-----------|---------|---------|------|
| P-S28 | 알림 센터 | `/notifications` | `NotificationListScreen` | → `/login` | → `/welcome` | → `/apply/status` | OK | |
| P-S29 | 개발 도구 | `/dev` | `PartnerDevMap` | OK | OK | OK | OK | dev only |
| P-S30 | 유저 전환 | `/dev/user-switch` | `DevUserSwitchScreen` | OK | OK | OK | OK | dev only |

---

## 3. 리다이렉트 검증 케이스

| # | 시나리오 | 입력 | 기대 결과 |
|---|----------|------|-----------|
| P-R01 | 비로그인 → 홈 | GUEST가 `/` 접근 | → `/login` |
| P-R02 | 비로그인 → 아무 보호 경로 | GUEST가 `/more/parties` 접근 | → `/login` |
| P-R03 | 미등록 → 홈 | NEEDS_APP가 `/` 접근 | → `/welcome` |
| P-R04 | 심사 중 → 홈 | PENDING이 `/` 접근 | → `/apply/status` |
| P-R05 | 등록 완료 → 로그인 | PARTNER가 `/login` 접근 | → `/` |
| P-R06 | 등록 완료 → 신청 | PARTNER가 `/apply` 접근 | → `/` |
| P-R07 | 미등록 → 웰컴 → 신청 | NEEDS_APP가 `/welcome` → 시작 | → `/apply` |

---

## 4. 파라미터별 엣지 케이스

| # | 화면 | 시나리오 | 기대 결과 |
|---|------|----------|-----------|
| P-E01 | 파티 상세 | 존재하지 않는 partyId | 에러 화면 또는 목록으로 이동 |
| P-E02 | 이벤트 상세 | 존재하지 않는 eventId | 에러 화면 |
| P-E03 | 신청 상세 | 존재하지 않는 applicationId | 에러 화면 |
| P-E04 | 정산 상세 | 존재하지 않는 settlementId | 에러 화면 |
| P-E05 | 멤버 권한 | 존재하지 않는 targetUserId | 에러 화면 |
| P-E06 | 파티 목록 | 파티 0건 | 빈 상태 + 생성 유도 |
| P-E07 | 신청 관리 | 신청 0건 | 빈 상태 화면 |
| P-E08 | 정산 | 정산 데이터 없음 | 빈 상태 화면 |
| P-E09 | 멤버 목록 | 본인만 존재 | 본인만 표시 |

---

## 5. 화면별 액션 매트릭스

### 5.1 홈 대시보드 (PartnerHomePage)

| 액션 | 기대 결과 | 에러 시나리오 |
|------|-----------|-------------|
| 다가오는 이벤트 카드 탭 | 이벤트 상세로 이동 | - |
| 매출 요약 카드 탭 | 정산 탭으로 이동 | - |
| 알림 아이콘 탭 | `/notifications`로 이동 | - |
| 장소 가이드 배너 탭 | `/guide/location`으로 이동 | - |
| 풀투리프레시 | 대시보드 갱신 | 네트워크 오류 |

### 5.2 신청 관리 (EventApplicationManagePage)

| 액션 | 기대 결과 | 에러 시나리오 |
|------|-----------|-------------|
| 신청 항목 탭 | `/applications/:id` 상세로 이동 | - |
| 이벤트 필터 변경 | 필터된 신청 목록 | - |
| 풀투리프레시 | 신청 목록 갱신 | 네트워크 오류 |

### 5.3 신청 상세 (PartnerApplicationDetailPage)

| 액션 | 기대 결과 | 에러 시나리오 |
|------|-----------|-------------|
| 승인 버튼 | 신청 승인 처리 → 목록 갱신 | 이미 처리됨 → 에러 |
| 거절 버튼 | 거절 확인 다이얼로그 → 처리 | - |
| 뒤로가기 | 신청 목록으로 복귀 | - |

### 5.4 정산 (SettlementPage)

| 액션 | 기대 결과 | 에러 시나리오 |
|------|-----------|-------------|
| 정산 항목 탭 | `/settlement/:id` 상세로 이동 | - |
| 계좌 관리 | `/settlement/bank-account`로 이동 | - |
| 풀투리프레시 | 정산 목록 갱신 | 네트워크 오류 |

### 5.5 계좌 관리 (BankAccountPage)

| 액션 | 기대 결과 | 에러 시나리오 |
|------|-----------|-------------|
| 계좌 등록/변경 | 은행 선택 → 계좌번호 입력 → 저장 | 유효성 검사 실패 |
| 계좌 삭제 | 삭제 확인 → 처리 | - |

### 5.6 더보기 (MorePage)

| 액션 | 기대 결과 | 에러 시나리오 |
|------|-----------|-------------|
| 파티 관리 | `/more/parties`로 이동 | - |
| 인증 관리 | `/more/verifications/manage`로 이동 | - |
| 알림 설정 | `/more/notification-settings`로 이동 | - |
| 멤버 관리 | `/more/partners/:id/members`로 이동 | - |
| 로그아웃 | 로그아웃 → `/login`으로 이동 | - |

### 5.7 파티 생성 위저드 (PartyCreateWizardPage)

| 액션 | 기대 결과 | 에러 시나리오 |
|------|-----------|-------------|
| Step 1: 기본정보 입력 | 다음 스텝으로 진행 | 필수 필드 누락 → 유효성 검사 |
| Step 2: 장소 입력 | 주소 검색 → 선택 → 다음 | 주소 검색 실패 |
| Step 3: 정원/연락처 | 다음 스텝 | - |
| Step 4: 입장규칙 | 다음 스텝 | - |
| Step 5: 티켓 설정 | 다음 스텝 | - |
| Step 6: 검토 + 제출 | 파티 생성 완료 → 상세로 이동 | 서버 오류 |
| 뒤로가기 (중간 스텝) | 이전 스텝으로 복귀 | - |
| 위저드 이탈 | 확인 다이얼로그 (작성 내용 유실 경고) | - |

### 5.8 파티 상세 (PartyDetailPage)

| 액션 | 기대 결과 | 에러 시나리오 |
|------|-----------|-------------|
| 편집 버튼 | `/more/parties/:id/edit`로 이동 | - |
| 이벤트 생성 | `/more/parties/:id/events/create`로 이동 | - |
| 이벤트 카드 탭 | 이벤트 상세로 이동 | - |
| 티켓 편집 | 티켓 편집 화면으로 이동 | - |
| 탭 전환 (정보/운영/이벤트/규칙) | 해당 탭 내용 표시 | - |

### 5.9 이벤트 생성 (EventCreatePage)

| 액션 | 기대 결과 | 에러 시나리오 |
|------|-----------|-------------|
| 날짜/시간 선택 | 선택 완료 | 과거 날짜 → 유효성 검사 |
| 이벤트 생성 완료 | 생성 → 이벤트 상세로 이동 | 서버 오류 |

### 5.10 멤버 관리 (PartnerMemberListPage)

| 액션 | 기대 결과 | 에러 시나리오 |
|------|-----------|-------------|
| 멤버 탭 | 권한 화면으로 이동 | - |
| 멤버 초대 | 초대 플로우 | - |

### 5.11 멤버 권한 (PartnerMemberPermissionPage)

| 액션 | 기대 결과 | 에러 시나리오 |
|------|-----------|-------------|
| 권한 변경 | 저장 → 목록 갱신 | 자기 자신 권한 변경 불가 |
| 멤버 제거 | 확인 다이얼로그 → 처리 | - |

### 5.12 인증 관리 (VerificationManagePage)

| 액션 | 기대 결과 | 에러 시나리오 |
|------|-----------|-------------|
| 인증 생성 | `/more/verifications/create`로 이동 | - |
| 인증 항목 탭 | 상세 표시 | - |

### 5.13 파트너 신청 위저드 (PartnerApplyPage)

| 액션 | 기대 결과 | 에러 시나리오 |
|------|-----------|-------------|
| Step 1: 기본정보 | 다음 | 필수 필드 누락 |
| Step 2: 사업자 정보 | 다음 | 사업자번호 유효성 |
| Step 3: 연락처/정산 | 다음 | - |
| Step 4: 서류 업로드 | 다음 | 파일 크기 초과 |
| Step 5: 검토 + 제출 | 신청 완료 → `/apply/status` | 서버 오류 |

---

## 6. 총 테스트 케이스 수

| 구분 | 수량 |
|------|------|
| 화면 진입 Smoke | 30 |
| 리다이렉트 검증 | 7 |
| 파라미터 엣지 케이스 | 9 |
| 화면별 액션 | 52 |
| **합계** | **98** |
