# partner-approve-application

파트너가 이벤트 신청을 단건/일괄 승인하는 EF. capacity 정합성은 DB RPC guard 로
보장한다.

## 이정표

| 파일                                                                       | 역할                                                                 |
| -------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| [index.ts](index.ts)                                                       | method/auth/action parse, service 호출, HTTP response mapping        |
| [input.ts](input.ts)                                                       | approve/bulk_approve action body validation                          |
| [approve_application_service.ts](approve_application_service.ts)           | permission check, application/event 조회, approval RPC orchestration |
| [index_test.ts](index_test.ts)                                             | L3 handler unit test (`fakeSupabase`)                                |
| [partner_approve_application_test.ts](partner_approve_application_test.ts) | HTTP wrapper/integration-style test                                  |

## 핵심 컨벤션

- 승인 가능 status / RPC 결과 mapping 은
  `_shared/domains/event/application_approval_policy.ts`.
- 권한 확인은 application 상태 검증보다 먼저 실행해 state leak 을 줄인다.
- capacity 초과/동시성은 `*_with_capacity_guard` Postgres RPC 에 맡긴다.

## 관련

- [../architecture.md](../architecture.md)
- [../_shared/domains/event/BLUEDOC.md](../_shared/domains/event/BLUEDOC.md)

---

_Reviewed: 2026-05-24 11:10_
