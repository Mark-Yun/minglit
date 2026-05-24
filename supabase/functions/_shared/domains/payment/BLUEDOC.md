# _shared/domains/payment

결제/환불 도메인의 **순수 비즈니스 로직**. IO (DB / 외부 API / HTTP) 없음.

## 이정표

| 파일                             | 역할                                             |
| -------------------------------- | ------------------------------------------------ |
| `application_status.ts`          | application status 분류, 무료 여부, 재신청 차단  |
| `cancel_order_policy.ts`         | user-cancel-order 취소 경로 결정                 |
| `payment_verification_policy.ts` | payment-verify 소유자/멱등성/결제 상태/금액 검증 |
| `refund_policy.ts`               | grace period + cutoff + 이벤트 시작 가드         |
| `*_test.ts`                      | 각 policy 의 mock 없는 unit tests                |

## 핵심 컨벤션

- pure 함수만 둔다. IO / Deno API / Date.now() 필요 시 인자로 받는다.
- payment-* EF 는 handler/service 에서 record 를 load 한 뒤 policy 에 snapshot
  을 넘긴다.
- 환불/승인/정산 같은 write 원자성은 EF policy 가 아니라 Postgres RPC 책임이다.
- breaking change 는 모든 payment EF 영향 → domain unit test + EF
  service/handler test 를 함께 확인한다.

## 관련

- [../BLUEDOC.md](../BLUEDOC.md)
- [../../architecture.md](../../architecture.md)
- [Issue #3676](https://github.com/supabase/cli/issues/3676)

---

_Reviewed: 2026-05-24 00:00_
