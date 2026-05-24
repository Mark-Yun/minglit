# order domain

이벤트 신청/주문 생성의 **pure business policy**.
DB/RPC/HTTP/logger/env/timer/random 없음.

## 이정표

| 파일                                                       | 역할                                                        |
| ---------------------------------------------------------- | ----------------------------------------------------------- |
| [create_order_policy.ts](create_order_policy.ts)           | event/ticket/profile/entry group/reapplication/payment 정책 |
| [create_order_policy_test.ts](create_order_policy_test.ts) | mock 없는 business-rule unit test                           |

## 핵심 컨벤션

- 입력은 EF service 가 이미 load 한 record snapshot 만 받는다.
- 실패는 `{ ok: false, status, message, code? }` 형태로 반환해 handler/service
  mapping 을 단순화한다.
- 현재 시각은 호출자가 `now` 로 주입한다.
- 원자성, DB lock, 재고 차감은 Postgres RPC 책임이다.

## 관련

- [../BLUEDOC.md](../BLUEDOC.md) — pure domain 가이드
- [../../architecture.md](../../architecture.md) — EF 레이어 표준

---

_Reviewed: 2026-05-24 00:00_
