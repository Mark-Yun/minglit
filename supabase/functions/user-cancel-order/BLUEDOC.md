# user-cancel-order

유저가 이벤트 신청/order 를 취소하고, 필요 시 PortOne 환불을 실행하는 EF.

## 이정표

| 파일                                                   | 역할                                                               |
| ------------------------------------------------------ | ------------------------------------------------------------------ |
| [index.ts](index.ts)                                   | user auth 확인, request parse, service 호출, HTTP response mapping |
| [input.ts](input.ts)                                   | `event_id` / optional `reason` request validation                  |
| [cancel_order_service.ts](cancel_order_service.ts)     | application 조회, 삭제/취소/update, refund orchestration           |
| [index_test.ts](index_test.ts)                         | L3 handler unit test (`fakeSupabase`)                              |
| [user_cancel_order_test.ts](user_cancel_order_test.ts) | HTTP wrapper/integration-style test                                |

## 핵심 컨벤션

- 취소 경로 결정은 `_shared/domains/payment/cancel_order_policy.ts` 에 둔다.
- pre-payment 는 application/verification submission 삭제, paid 는 refund 후
  cancel update.
- 환불 성공 후 DB update 실패는 기존 정책대로 non-fatal 로 유지한다.

## 관련

- [../architecture.md](../architecture.md)
- [../_shared/domains/payment/BLUEDOC.md](../_shared/domains/payment/BLUEDOC.md)

---

_Reviewed: 2026-05-24 00:00_
