# 계획: 파티 체크인 및 오프라인 QR 시스템

## Phase 1: 백엔드 및 암호화 구현
- [ ] Task: Ed25519 키 쌍 생성 및 관리 로직 구현 (Supabase Edge Function)
    - [ ] 서버용 Private Key/Public Key 생성 및 Secure Config 저장.
- [ ] Task: 티켓 발권(서명) API 구현
    - [ ] `apply_event` 완료 시 서명된 티켓 토큰(Signed Token)을 생성하여 반환하도록 로직 수정.
- [ ] Task: 체크인 검증 API 구현
    - [ ] `verify_ticket`: 서명 검증 및 `event_participants` 상태 업데이트.
- [ ] Task: Conductor - 사용자 수동 검증 'Phase 1: 서명 및 검증 로직' (Protocol in workflow.md)

## Phase 2: 유저 앱 (QR Wallet) 구현 (`app_user`)
- [ ] Task: 티켓 로컬 저장소 구현
    - [ ] `FlutterSecureStorage`를 이용해 발권된 티켓 토큰 캐싱 로직 작성.
- [ ] Task: QR 코드 뷰어 위젯 구현
    - [ ] `qr_flutter` 적용 및 데이터 바인딩.
    - [ ] 캡처 방지용 **스캔 라인 애니메이션** 구현.
    - [ ] 화면 밝기 제어 연동.
- [ ] Task: Conductor - 사용자 수동 검증 'Phase 2: 오프라인 QR 생성' (Protocol in workflow.md)

## Phase 3: 파트너 앱 (Scanner) 구현 (`app_partner`)
- [ ] Task: QR 스캐너 화면 구현
    - [ ] `mobile_scanner` 적용 및 카메라 권한 처리.
- [ ] Task: 체크인 로직 연동 및 피드백 UI 구현
    - [ ] 스캔 후 서버 API 호출.
    - [ ] **성공/실패/중복**에 따른 명확한 **풀스크린 색상 피드백(초록/빨강)** 및 사운드/진동 효과.
- [ ] Task: Conductor - 사용자 수동 검증 'Phase 3: 체크인 통합 테스트' (Protocol in workflow.md)
