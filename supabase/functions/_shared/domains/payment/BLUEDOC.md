# _shared/domains/payment

결제 / 환불 도메인의 **순수 비즈니스 로직** 모음. IO (DB / 외부 API / HTTP) 없음. 모든 payment-* EF 가 import.

## 위치 — Supabase 제약 반영

Hexagonal 의 도메인 코어를 nested EF 폴더에 못 둠 (Supabase CLI Issue #3676 — nested entrypoint 미지원). 차선: `_shared/` 안 도메인별 grouping. EF 폴더는 flat 유지.

## 파일

| 파일 | 역할 |
|---|---|
| `application_status.ts` | application status 분류 (`isPaid` / `isPrePayment` / `isFinal`) + `isFreeApplication`. 모든 payment EF 가 사용 |
| `application_status_test.ts` | pure unit tests (mock 0) |
| (관련 도메인) `_shared/domains/event/availability.ts` | `isEventStarted` (refund cutoff 등에서 사용) |
| `refund_policy.ts` | `verifyRefundEligibility` — grace period + cutoff + 이벤트 시작 가드 (Fix #1235) |
| `refund_policy_test.ts` | pure unit tests (mock 0) |
| (예정) `refund_amount.ts` | 환불 금액 계산 (Fix #2131 후속) |

## 사용 패턴

```ts
// payment EF index.ts
import { classifyApplicationStatus } from "../_shared/domains/payment/application_status.ts";

const { isPaid, isPrePayment } = classifyApplicationStatus(application.status);
if (isPrePayment) { /* pre-payment 분기 */ }
if (isPaid) { /* paid 분기 */ }
```

## 변경 정책

- pure 함수만 — IO / Deno API / Date.now() 호출 시 인자로 받음 (testable)
- breaking change → 모든 payment EF 영향 → 전수 unit test 가 자동 가드
- 새 함수 추가 자유 (사용 안 하면 cost 0)

## 관련

- [_shared/BLUEDOC.md](../../BLUEDOC.md) — _shared 전체
- [EF 아키텍처 RFC](../../../../../docs/architecture/) (예정) — 갈래 A 의 도입 배경
- [Issue #3676](https://github.com/supabase/cli/issues/3676) — nested entrypoint 미지원 (본 구조 선택 이유)
