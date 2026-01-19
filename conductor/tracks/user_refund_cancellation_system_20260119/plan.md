# 계획: 유저 환불 정책 및 취소 시스템

## Phase 1: 환불 정책 및 계산 로직
- [ ] Task: `RefundPolicy` 모델 및 `RefundCalculator` 구현.
- [ ] Task: `payment-cancel-v1` Edge Function 구현
    - [ ] Iamport V1 취소 API 연동.
    - [ ] 부분 환불 지원.

## Phase 2: UI 구현
- [ ] Task: 티켓 상세 화면 [예매 취소] 버튼 추가.
- [ ] Task: 환불 예상 금액 안내 팝업 구현.

## Phase 3: 통합
- [ ] Task: 취소 버튼 클릭 시 Edge Function 호출 연동.
- [ ] Task: 취소 완료 후 UI 갱신.
