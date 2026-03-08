# 명세서: 결제 서버 검증 및 웹훅 처리 (Payment Verification System)

## 1. 개요
클라이언트 사이드에서 이루어진 결제 결과의 무결성을 보장하기 위해 서버 사이드 검증 로직을 구현합니다. PortOne API를 통해 실제 결제 내역을 조회하여 금액 위변조를 방지하고, Webhook을 통해 비동기 결제 상태 변경(가상계좌 입금 완료 등)을 실시간으로 반영합니다.

## 2. 주요 기능

### 2.1. 서버 검증 API (Edge Function)
- **API:** `verify-payment`
- **기능:**
    - 클라이언트로부터 `payment_id` 수신.
    - PortOne REST API를 호출하여 해당 결제 건의 상태(`paid`)와 금액(`amount`) 조회.
    - DB의 주문 정보(`event_applications`)와 비교 검증.
    - **검증 성공:** 상태를 `approved` 또는 `ticket_issued`로 변경.
    - **검증 실패:** 결제 취소(환불) 로직 실행 및 상태 `verification_failed` 기록.

### 2.2. Webhook 처리
- **API:** `portone-webhook`
- **기능:**
    - PortOne 서버로부터 결제 상태 변경 알림 수신.
    - 서명(Signature) 검증으로 요청 위변조 방지.
    - 결제 상태(`paid`, `cancelled`)에 따라 DB 업데이트 및 알림 발송.

### 2.3. 보안 강화
- PortOne API Key 및 Secret을 Supabase Secret으로 안전하게 관리.
- 멱등성(Idempotency) 보장: 중복된 Webhook 요청이 와도 안전하게 처리.

## 3. 기술 스택 및 아키텍처
- **Client Package:** `minglit_iamport_v1` (신규)
    - **Dependency:** `iamport_flutter` (V1).
    - **Role:** 결제 및 본인인증 창 호출.
- **Server:** Supabase Edge Function (`verify-payment-v1`).
- **Payment API:** Iamport API V1 (`api.iamport.kr`).
    - 인증 방식: Access Token 발급 (`/users/getToken`) 후 Bearer Token 사용.

## 4. 수락 기준
- [ ] 클라이언트 결제 후 서버 검증 API가 호출되어야 함.
- [ ] 위변조된 금액으로 결제 시도 시 검증이 실패하고 자동 환불되어야 함.
- [ ] Webhook을 통해 가상계좌 입금 확인 시 티켓이 발권되어야 함.
