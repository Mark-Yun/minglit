# _shared/domains/event

이벤트 도메인의 **순수 비즈니스 로직**. IO 없음.

## 이정표

| 파일                             | 역할                                                            |
| -------------------------------- | --------------------------------------------------------------- |
| `availability.ts`                | 신청/편집 가능 status, capacity, 시작 시각, 티켓 매진 predicate |
| `application_approval_policy.ts` | partner approval 가능 status + capacity guard RPC 결과 mapping  |
| `participant.ts`                 | event_participants check-in 분류                                |
| `*_test.ts`                      | 각 policy 의 mock 없는 unit tests                               |

## 핵심 컨벤션

- `isEventOpenForApplication`: scheduled / active 신청 가능.
- `isEventEditableByPartner`: scheduled 만 편집 가능.
- 시간 비교는 `now: Date` 를 주입할 수 있게 둔다.
- capacity 원자성은 EF policy 가 아니라 Postgres RPC guard 책임이다.
- breaking change 는 user-create-order / apply-event / partner-manage-event /
  approval EF 영향.

## 알려진 정합성 이슈

- `apply-event/index.ts` 의 status 가드는 `scheduled only` 로 Fix #998 의
  user-create-order 와 불일치. 별도 이슈로 관리.

## 관련

- [../BLUEDOC.md](../BLUEDOC.md)
- [payment/BLUEDOC.md](../payment/BLUEDOC.md)

---

_Reviewed: 2026-05-24 00:00_
