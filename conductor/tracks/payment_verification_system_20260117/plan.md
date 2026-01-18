# 계획: 결제 서버 검증 및 웹훅 처리

## Phase 1: 서버 검증 Edge Function 구현
- [ ] Task: PortOne API 클라이언트 모듈 작성
    - [ ] Access Token 발급 및 캐싱 로직.
    - [ ] `getPaymentDetails` 함수 구현.
- [ ] Task: `verify-payment` Edge Function 구현
    - [ ] DB 주문 조회 및 PortOne 결제 내역 비교 검증 로직.
    - [ ] 검증 결과에 따른 DB 트랜잭션 처리.
- [ ] Task: Conductor - User Manual Verification 'Phase 1: 결제 검증 테스트' (Protocol in workflow.md)

## Phase 2: Webhook 핸들러 구현
- [ ] Task: `portone-webhook` Edge Function 구현
    - [ ] Webhook 서명 검증 로직.
    - [ ] 이벤트 타입별(입금완료, 취소) 분기 처리.
- [ ] Task: PortOne 관리자 콘솔 설정 가이드 작성
    - [ ] Webhook URL 등록 및 테스트 방법 문서화.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Webhook 수신 테스트' (Protocol in workflow.md)

## Phase 3: 통합 및 예외 처리
- [ ] Task: 앱(`app_user`) 결제 로직에 서버 검증 연동
    - [ ] `EventApplicationController`에서 결제 성공 후 `verify-payment` 호출.
- [ ] Task: 실패 시 자동 환불/취소 로직 구현
    - [ ] 검증 실패 시 결제 취소 API 호출.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: 전체 결제 시나리오 검증' (Protocol in workflow.md)
