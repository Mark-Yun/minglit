# 계획: 유저 앱 결제 UX 및 티켓 발권 흐름

## Phase 1: 결제 준비 및 주문 생성
- [ ] Task: `EventApplicationController`에 `createOrder` 메서드 추가
    - [ ] `event_applications` 테이블에 `pending_payment` 상태로 데이터 생성.
    - [ ] `merchant_uid` 반환.
- [ ] Task: `TicketSelectionSheet` 결제 버튼 연동
    - [ ] 주문 생성 후 결제 프로세스로 진입하는 로직 작성.

## Phase 2: Iamport 결제 연동
- [ ] Task: `minglit_iamport_v1` 결제 호출
    - [ ] `PaymentService.requestPayment` 호출.
    - [ ] PG사별(다날 등) 파라미터 구성 (`pg`, `pay_method` 등).
- [ ] Task: 결제 결과 핸들링
    - [ ] 성공: `verify-payment-v1` 호출.
    - [ ] 실패: 에러 처리.

## Phase 3: 결과 화면 및 티켓 확인
- [ ] Task: 결제 성공/실패 UI 피드백
    - [ ] 로딩 인디케이터 및 성공 스낵바.
- [ ] Task: 티켓 화면 라우팅
    - [ ] 결제 완료 후 `/tickets/:ticketId`로 이동.
