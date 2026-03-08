# 명세서: 유저 앱 결제 UX 및 티켓 발권 흐름 (User Payment & Ticketing Flow)

## 1. 개요
유저가 파티(이벤트) 상세 화면에서 원하는 티켓을 선택하고, `Iamport V1` 결제창을 통해 실제 결제를 수행한 뒤, 최종적으로 발권된 티켓을 확인하는 엔드투엔드(E2E) 구매 경험을 구현합니다.

## 2. 주요 기능

### 2.1. 결제 진입 (Ticket Selection)
- **UI:** `TicketSelectionSheet`에서 수량 선택 후 [결제하기] 버튼 클릭.
- **로직:**
    - 재고 확인 (Client-side 1차, Server-side 2차).
    - `EventApplication` 레코드 생성 (상태: `pending_payment`).
    - 생성된 `merchant_uid`로 결제 프로세스 시작.

### 2.2. 결제 수행 (Iamport V1)
- **패키지:** `minglit_iamport_v1` (`PaymentService`).
- **파라미터:** `merchant_uid`, `amount`, `buyer_name`, `buyer_tel`, `name` (티켓명).
- **흐름:**
    - 앱: `IamportPayment` 위젯 호출 (PG사 결제창).
    - 웹: `iamport.payment.js` 연동 (새 창/Redirect).

### 2.3. 결제 검증 및 티켓 발권
- **성공 시:**
    - `imp_uid`를 받아 백엔드 `verify-payment-v1` 호출.
    - 서버 검증 성공 시 `EventApplication` 상태 -> `approved`.
    - `tickets` 테이블에 실제 티켓 레코드 생성.
- **실패 시:**
    - 에러 메시지 표시 및 `EventApplication` 상태 -> `payment_failed` 처리.

### 2.4. 결과 화면
- **성공:** "결제가 완료되었습니다!" -> 티켓 상세 화면(`MyTicketScreen`)으로 이동.
- **실패:** 상세 에러 사유 표시 및 재시도 유도.

## 3. 기술 스택
- **Frontend:** `minglit_iamport_v1`
- **Backend:** `verify-payment-v1` (Edge Function)

## 4. 수락 기준
- [ ] 유저가 티켓 선택 후 결제 버튼을 누르면 PG사 결제창이 떠야 함.
- [ ] 결제 완료 후 서버 검증을 거쳐 DB에 티켓이 생성되어야 함.
- [ ] 결제 성공 시 유저는 즉시 자신의 티켓을 확인할 수 있어야 함.
