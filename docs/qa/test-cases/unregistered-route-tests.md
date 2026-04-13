# 라우트 미등록 화면 위젯/통합 테스트 정의

> 목적: GoRouter에 등록되지 않아 딥링크/URL 진입이 불가능한 화면들의 테스트 전략 정의.
> 이 화면들은 `Navigator.push`로만 접근 가능하므로 runtime-qa 시나리오가 아닌 **자동화 테스트**로 검증한다.

---

## 대상 화면 목록

| # | 화면 | 앱 | 파일 경로 | 네비게이션 방식 | 진입점 |
|---|------|-----|-----------|----------------|--------|
| 1 | MatchingVoteScreen | app_user | `features/event/matching/matching_vote_screen.dart` | Navigator.push | EventNowBar → 바텀시트 |
| 2 | QRScannerScreen | app_partner | `features/checkin/qr_scanner_screen.dart` | Navigator.push (MaterialPageRoute) | PartyListPage AppBar 아이콘 |
| 3 | MatchingSettingsScreen | app_partner | `features/party/matching/matching_settings_screen.dart` | 미구현 (네비게이션 없음) | — |
| 4 | ReviewVerificationScreen | app_partner | `features/verification/review/review_verification_screen.dart` | Dev 전용 (PartnerDevMap) | DevMap screenBuilder |
| 5 | TicketTemplateManageScreen | app_partner | `features/party/ticket/ui/ticket_template_manage_screen.dart` | Navigator.push | 파티 생성 위저드 내부 |
| 6 | TicketTemplateCreatePage | app_partner | `features/party/ticket/ticket_template_create_page.dart` | Navigator.push (반환값) | TicketTemplateManageScreen |

---

## 테스트 전략

### GoRouter 미등록의 의미

이 화면들은 URL 기반 네비게이션(딥링크, 브라우저 뒤로가기)이 불가능하다.
따라서:
- **runtime-qa smoke 테스트 대상이 아님** (URL 직접 진입 불가)
- **위젯 테스트 또는 통합 테스트로 검증** 해야 함
- 진입 경로가 특정 화면의 버튼/액션에 의존하므로 **해당 진입점 기준으로 테스트 설계**

---

## URT-01: MatchingVoteScreen 위젯 테스트 [P0] — app_user

> 매칭 투표는 밍글릿의 핵심 가치. 투표 UI + 상태 관리가 정확해야 함.

### 테스트 파일
- 기존: `apps/app_user/test/integration/cuj_matching_vote_test.dart` (CUJ 통합 테스트)
- 추가 필요: 위젯 단위 테스트

### 테스트 케이스

| # | 케이스 | 입력 | 기대 결과 | 테스트 유형 |
|---|--------|------|-----------|------------|
| URT-01-A | 참가자 프로필 카드 렌더링 | `eventId` + 참가자 2명 목 데이터 | 프로필 카드 2장 표시 (이미지, 이름, 소개) | 위젯 |
| URT-01-B | 좋아요 투표 | 프로필 카드 → 좋아요 탭 | 투표 API 호출 + 다음 카드 전환 | 위젯 |
| URT-01-C | 패스 투표 | 프로필 카드 → 패스 탭 | 투표 API 호출 + 다음 카드 전환 | 위젯 |
| URT-01-D | 모든 투표 완료 | 마지막 카드 투표 | "투표 완료" 안내 + 화면 닫기 | 위젯 |
| URT-01-E | 참가자 0명 | 참가자 빈 목록 | "아직 참가자가 없습니다" 빈 상태 | 위젯 |
| URT-01-F | 네트워크 오류 시 투표 | 투표 API 실패 mock | 에러 메시지 + 재시도 (카드 유지) | 위젯 |
| URT-01-G | 진입 플로우 (EventNowBar → 투표) | 체크인 완료 이벤트 | EventNowBar 표시 → 탭 → 바텀시트 → 투표 화면 | 통합 |

### 구현 가이드
```
테스트 파일: apps/app_user/test/widget/matching_vote_screen_test.dart
필요 Mock: MatchingRepository, EventRepository
핵심 검증: 투표 상태 전이 (idle → voting → completed), API 호출 파라미터
```

---

## URT-02: QRScannerScreen 위젯 테스트 [P0] — app_partner

> 체크인 현장에서 사용. 카메라 + QR 파싱 + 서버 검증 체인 테스트.

### 테스트 파일
- 기존: `apps/app_partner/test/integration/cuj_checkin_qr_test.dart` (CUJ 통합 테스트)
- 추가 필요: 위젯 단위 테스트 (카메라 mock 기반)

### 테스트 케이스

| # | 케이스 | 입력 | 기대 결과 | 테스트 유형 |
|---|--------|------|-----------|------------|
| URT-02-A | 유효한 QR 스캔 | 정상 TicketToken JSON | 체크인 성공 피드백 (녹색) + 유저명 표시 | 위젯 |
| URT-02-B | 이미 체크인된 QR | 이미 처리된 토큰 | `alreadyCheckedIn` → "이미 체크인됨" (노란색) | 위젯 |
| URT-02-C | 유효하지 않은 QR | 잘못된 JSON 또는 비-밍글릿 QR | `invalid` → "유효하지 않은 QR" (빨간색) | 위젯 |
| URT-02-D | 다른 이벤트 QR | 다른 eventId의 토큰 | `invalid` → "이 이벤트의 QR이 아닙니다" | 위젯 |
| URT-02-E | 서버 통신 실패 | 네트워크 오류 mock | `error` → 에러 안내 + 재시도 | 위젯 |
| URT-02-F | 자동 리셋 | 스캔 성공 후 3초 | idle 상태로 복귀 → 다음 스캔 대기 | 위젯 |
| URT-02-G | 진입 플로우 (PartyListPage → 스캐너) | PARTNER 상태 | PartyListPage AppBar QR 아이콘 탭 → QRScannerScreen | 통합 |

### 구현 가이드
```
테스트 파일: apps/app_partner/test/widget/qr_scanner_screen_test.dart
필요 Mock: CheckinRepository, MobileScannerController (카메라 mock)
핵심 검증: CheckinResult 상태 전이, 3초 자동 리셋 타이머, QR JSON 파싱
```

---

## URT-03: MatchingSettingsScreen 위젯 테스트 [P1] — app_partner

> 매칭 설정 화면. 현재 네비게이션 미구현 — 화면 자체의 동작만 위젯 테스트로 검증.

### 테스트 케이스

| # | 케이스 | 입력 | 기대 결과 | 테스트 유형 |
|---|--------|------|-----------|------------|
| URT-03-A | 초기 렌더링 | `eventId` | 매칭 설정 폼 표시 (매칭 방식, 시간, 제한 등) | 위젯 |
| URT-03-B | 설정 변경 → 저장 | 폼 값 수정 → 저장 | API 호출 + 성공 피드백 | 위젯 |
| URT-03-C | 유효성 검사 | 필수 필드 누락 | 에러 메시지 표시 | 위젯 |
| URT-03-D | 서버 오류 | 저장 API 실패 | 에러 안내 + 재시도 | 위젯 |

### 구현 가이드
```
테스트 파일: apps/app_partner/test/widget/matching_settings_screen_test.dart
필요 Mock: MatchingSettingsRepository
주의: 네비게이션 미구현 상태이므로 진입 경로 통합 테스트는 네비게이션 구현 후 추가
```

---

## URT-04: ReviewVerificationScreen 위젯 테스트 [P1] — app_partner

> 유저 자격 심사 화면. 현재 Dev 전용 접근만 가능.

### 테스트 케이스

| # | 케이스 | 입력 | 기대 결과 | 테스트 유형 |
|---|--------|------|-----------|------------|
| URT-04-A | 심사 대기 목록 렌더링 | 심사 대기 인증 요청 3건 | 요청 카드 3장 표시 (유저명, 인증 유형, 제출일) | 위젯 |
| URT-04-B | 심사 승인 | 요청 카드 → 승인 | 상태 변경 + 목록 갱신 | 위젯 |
| URT-04-C | 심사 거절 | 요청 카드 → 거절 + 사유 입력 | 상태 변경 + 사유 전달 | 위젯 |
| URT-04-D | 빈 목록 | 심사 대기 0건 | 빈 상태 UI | 위젯 |
| URT-04-E | 서버 오류 | 승인/거절 API 실패 | 에러 안내 + 재시도 | 위젯 |

### 구현 가이드
```
테스트 파일: apps/app_partner/test/widget/review_verification_screen_test.dart
필요 Mock: VerificationRepository
주의: 프로덕션 네비게이션 미구현. CUJ-P07에 심사 플로우 스텝 추가 시 통합 테스트도 필요
```

---

## URT-05: TicketTemplate 화면 위젯 테스트 [P1] — app_partner

> 파티 레벨 티켓 템플릿 관리. Navigator.push + 반환값 패턴.

### 대상 화면
1. **TicketTemplateManageScreen** — 템플릿 목록 관리
2. **TicketTemplateCreatePage** — 템플릿 생성/편집 (반환값: `TicketTemplate`)

### 테스트 케이스

| # | 케이스 | 화면 | 입력 | 기대 결과 | 테스트 유형 |
|---|--------|------|------|-----------|------------|
| URT-05-A | 템플릿 목록 렌더링 | Manage | `partyId` + 템플릿 2건 | 템플릿 카드 2장 (이름, 가격, 수량) | 위젯 |
| URT-05-B | 빈 템플릿 목록 | Manage | 템플릿 0건 | 빈 상태 + 생성 유도 | 위젯 |
| URT-05-C | 템플릿 생성 | Create | 이름/가격/수량 입력 → 저장 | `Navigator.pop(TicketTemplate)` 반환 | 위젯 |
| URT-05-D | 템플릿 편집 | Create | `initialTicket` + 수정 → 저장 | 수정된 `TicketTemplate` 반환 | 위젯 |
| URT-05-E | 유효성 검사 | Create | 가격 음수, 수량 0 | 에러 메시지 + 저장 차단 | 위젯 |
| URT-05-F | 입장그룹 연동 | Create | `entryGroups` 전달 | 입장그룹 선택 UI 표시 | 위젯 |
| URT-05-G | 진입 플로우 (위저드 → 템플릿) | Manage | 파티 생성 위저드 Step 5 | 티켓 설정 스텝에서 템플릿 관리 진입 | 통합 |

### 구현 가이드
```
테스트 파일:
  - apps/app_partner/test/widget/ticket_template_manage_screen_test.dart
  - apps/app_partner/test/widget/ticket_template_create_page_test.dart
필요 Mock: PartyRepository (partyId → party with entryGroups)
핵심 검증: Navigator.pop 반환값, 유효성 검사, entryGroups 전달
```

---

## 총 테스트 케이스 요약

| ID | 화면 | 우선순위 | 위젯 | 통합 | 합계 |
|----|------|----------|------|------|------|
| URT-01 | MatchingVoteScreen | P0 | 6 | 1 | 7 |
| URT-02 | QRScannerScreen | P0 | 6 | 1 | 7 |
| URT-03 | MatchingSettingsScreen | P1 | 4 | 0 | 4 |
| URT-04 | ReviewVerificationScreen | P1 | 5 | 0 | 5 |
| URT-05 | TicketTemplate 화면 | P1 | 6 | 1 | 7 |
| **합계** | | | **27** | **3** | **30** |

---

## SWE 구현 시 참고사항

1. **MobileScanner Mock**: `mobile_scanner` 패키지의 카메라를 mock하려면 `MobileScannerController`를 DI로 주입받는 구조가 필요. 현재 `QRScannerScreen`이 직접 생성하고 있다면 테스트를 위한 리팩토링 필요.
2. **Navigator.pop 반환값 테스트**: `TicketTemplateCreatePage`의 `Navigator.pop(result)` 패턴은 `tester.tap()` → `Navigator`를 mock하여 반환값을 검증.
3. **MatchingSettingsScreen**: 네비게이션 미구현 상태이므로 통합 테스트는 네비게이션 구현 이슈와 연동.
4. **ReviewVerificationScreen**: Dev 전용 접근만 가능. 프로덕션 네비게이션 구현 시 CUJ-P07에 심사 스텝 추가 필요 (별도 이슈).
