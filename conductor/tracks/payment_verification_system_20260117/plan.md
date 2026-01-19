# 계획: 결제 서버 검증 및 웹훅 처리

## Phase 1: `minglit_iamport_v1` 패키지 구축
- [x] Task: 패키지 스캐폴딩 및 `iamport_flutter` 연동 c7aab34
    - [x] `shared/packages/minglit_iamport_v1` 생성.
    - [x] 결제(`PaymentService`) 및 본인인증(`CertificationService`) 인터페이스 구현.
- [x] Task: Conductor - User Manual Verification 'Phase 1: 패키지 동작 확인' (Protocol in workflow.md)

## Phase 2: 서버 검증 Edge Function 구현 (V1)
- [x] Task: Iamport V1 API 클라이언트 모듈 작성 c7aab34
    - [x] Access Token 발급(`/users/getToken`) 및 캐싱.
- [x] Task: `verify-payment-v1` Edge Function 구현 c7aab34
    - [x] DB 주문 조회 및 Iamport 결제 내역 비교 검증.
- [x] Task: `verify-identity-v1` Edge Function 구현 (리팩토링) c7aab34
    - [x] 기존 로직을 V1 API(`api.iamport.kr`) 호출 방식으로 변경.
- [ ] Task: Conductor - User Manual Verification 'Phase 2: 결제/인증 검증 테스트' (Protocol in workflow.md)

## Phase 3: Webhook 및 통합 처리
- [ ] Task: `portone-webhook` 핸들러 구현 (V1 호환).
- [ ] Task: 앱 연동 (`app_user`)
    - [x] `IdentityVerificationScreen`을 `minglit_iamport_v1`으로 교체.
    - [ ] `EventApplicationController` 결제 로직 연동.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: 전체 결제 시나리오 검증' (Protocol in workflow.md)
