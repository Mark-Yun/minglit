# payment-verify

유저 결제 완료 후 PortOne/Iamport 결제를 검증하고 application 상태를 승인
처리하는 EF.

## 이정표

| 파일                                                   | 역할                                                               |
| ------------------------------------------------------ | ------------------------------------------------------------------ |
| [index.ts](index.ts)                                   | user auth 확인, request parse, service 호출, HTTP response mapping |
| [input.ts](input.ts)                                   | `imp_uid` / `merchant_uid` request validation                      |
| [verify_payment_service.ts](verify_payment_service.ts) | order 조회, PortOne 조회/취소, DB update, Statsig orchestration    |
| [index_test.ts](index_test.ts)                         | L3 handler unit test (`fakeSupabase` + fetch mock)                 |
| [payment_verify_test.ts](payment_verify_test.ts)       | HTTP wrapper/integration-style test                                |

## 핵심 컨벤션

- 결제 상태/금액/멱등성 policy 는 `_shared/domains/payment` 에 둔다.
- `merchant_uid` 는 `event_applications.id` 이며 owner check 를 service_role EF
  에서 명시한다.
- 금액 mismatch 는 자동 취소를 시도하고 실패해도 검증 요청은 400 으로 종료한다.

## 관련

- [../architecture.md](../architecture.md)
- [../_shared/domains/payment/BLUEDOC.md](../_shared/domains/payment/BLUEDOC.md)

---

_Reviewed: 2026-05-24 00:00_
