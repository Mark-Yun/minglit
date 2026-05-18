# _shared/domains/event

이벤트 도메인의 **순수 비즈니스 로직**. IO 없음. event status / capacity 가드 + 시간 비교.

## 파일

| 파일 | 역할 |
|---|---|
| `availability.ts` | event status (`isEventOpenForApplication` / `isEventEditableByPartner`), capacity (`isEventFull` / `isTicketSoldOut`), 시작 시각 (`isEventStarted`) |
| `availability_test.ts` | pure unit tests (mock 0) |
| `participant.ts` | event_participants 분류 (`isCheckedIn`). 매칭 / 투표 EF 의 자격 가드 |
| `participant_test.ts` | pure unit tests (mock 0) |

## 두 status predicate 의 의미 차이 (중요)

| Predicate | scheduled | active | 그 외 | 의미 |
|---|---|---|---|---|
| `isEventOpenForApplication` | ✅ | ✅ | ❌ | 유저가 신청 시도 가능 — Fix #998 |
| `isEventEditableByPartner`  | ✅ | ❌ | ❌ | 파트너가 취소/규칙 변경 가능 — state machine 가드 |

`active` 에서 갈림: 진행 중 이벤트에 유저는 신청 가능하지만 파트너는 편집 불가.

## 사용 패턴

```ts
// user-create-order
import { isEventOpenForApplication, isEventStarted, isEventFull, isTicketSoldOut }
  from "../_shared/domains/event/availability.ts";

if (!isEventOpenForApplication(event.status)) return errorResponse(...);
if (isEventStarted(event.start_time)) return errorResponse(...);
if (isEventFull(event.current_participants, event.max_participants)) ...
if (isTicketSoldOut(ticket.sold_count, ticket.quantity)) ...

// partner-manage-event (cancel 분기)
import { isEventEditableByPartner } from "../_shared/domains/event/availability.ts";
if (!isEventEditableByPartner(event.status)) return errorResponse(...);
```

## 변경 정책

- pure 만 — IO 필요 시 인자로 주입 (`now: Date`)
- breaking change → user-create-order / apply-event / partner-manage-event / partner-manage-match 전부 영향, unit test 가 자동 가드
- 신규 predicate 추가 자유

## 알려진 정합성 이슈

- `apply-event/index.ts` 의 status 가드는 `scheduled only` (active 거부) — Fix #998 의 `user-create-order` 와 불일치. 별도 이슈로 관리.

## 관련

- [_shared/domains/BLUEDOC.md](../BLUEDOC.md)
- [payment/BLUEDOC.md](../payment/BLUEDOC.md) — paid 후 처리 흐름

---
_Reviewed: 2026-05-18 11:19_
