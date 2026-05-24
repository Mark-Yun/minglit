# user-create-order

유저가 이벤트 티켓으로 신청/order 를 생성하는 Edge Function. 결제 전 핵심
business rule 을 검증한다.

## 이정표

| 파일                                                   | 역할                                                                     |
| ------------------------------------------------------ | ------------------------------------------------------------------------ |
| [index.ts](index.ts)                                   | user auth 확인, request parse, service 호출, HTTP response mapping       |
| [input.ts](input.ts)                                   | request body schema/type validation                                      |
| [create_order_service.ts](create_order_service.ts)     | event/ticket/profile 조회, policy 적용, RPC/update/Statsig orchestration |
| [index_test.ts](index_test.ts)                         | L3 handler unit test (`fakeSupabase`)                                    |
| [user_create_order_test.ts](user_create_order_test.ts) | HTTP wrapper/integration-style test                                      |

## 핵심 컨벤션

- business rule 은 `_shared/domains/order/create_order_policy.ts` 에 먼저
  추가한다.
- DB/RPC 순서와 fail-open/fail-closed 결정은 service test 로 고정한다.
- application/order write 원자성은 최종적으로 Postgres RPC 로 이동한다.

## 관련

- [../architecture.md](../architecture.md) — EF 표준 레이어
- [../_shared/domains/order/BLUEDOC.md](../_shared/domains/order/BLUEDOC.md)

---

_Reviewed: 2026-05-24 00:00_
