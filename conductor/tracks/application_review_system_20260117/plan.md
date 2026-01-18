# 계획: 파티 참여자 심사 및 환불 관리 시스템

## Phase 1: 백엔드 환불 로직 및 트리거 구현
- [x] Task: Portone 결제 취소 Edge Function 구현 e1d2bf7
    - [x] `cancel_payment(payment_id, reason)` 함수 작성 (Portone REST API 연동).
- [x] Task: 거절 시 자동 환불 트리거 구현 e1d2bf7
    - [x] `event_applications` 상태가 `rejected`로 변경될 때 Edge Function을 호출하는 Database Webhook 또는 PG Trigger 작성.
    - [x] 환불 결과(`refund_status`) 업데이트 로직 구현.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: 환불 로직 테스트' (Protocol in workflow.md)

## Phase 2: 파트너 앱 심사 UI 구현 (`app_partner`)
- [ ] Task: 신청 목록 리스트 UI 구현
    - [ ] 이벤트별 대기 중인 신청 건 조회 및 표시.
- [ ] Task: 상세 심사 및 거절 팝업 구현
    - [ ] 유저 정보/제출 자료 확인 뷰 작성.
    - [ ] 거절 사유 선택(라디오 버튼) 및 직접 입력 다이얼로그 구현.
- [ ] Task: 승인/거절 API 연동
    - [ ] `reviewRequest` (기존 repo 활용) 호출 및 UI 갱신.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: 심사 기능 확인' (Protocol in workflow.md)

## Phase 3: 유저 알림 및 재신청 유도 (`app_user`)
- [ ] Task: 심사 결과 알림 핸들링
    - [ ] 승인/거절 푸시 알림 수신 시 딥링크 처리 확인.
- [ ] Task: 재신청 플로우 확인
    - [ ] 거절된 유저가 파티 화면 진입 시 "신청하기" 버튼 활성화 여부 확인 (기존 `EventAdmissionController` 로직 재검증).
- [ ] Task: Conductor - User Manual Verification 'Phase 3: E2E 시나리오 테스트' (Protocol in workflow.md)
