# bootstrap tests

`minglit_kit/lib/src/bootstrap` 의 startup 정책과 fatal UI 테스트.

## 이정표

| 항목 | 무엇 |
|---|---|
| `minglit_startup_plan_test.dart` | critical/platform/degradable 실패 정책과 timeout 검증 |
| `startup_fatal_error_view_test.dart` | MDS 기반 fatal startup 화면 렌더링 검증 |

## 핵심 컨벤션

- SDK 실제 초기화 없이 순수 step callback 으로 정책만 테스트한다.
- critical 실패는 throw 를 기대하고, degradable/platform 실패는 결과 수집을 기대한다.
- UI 테스트는 MDS public component 를 통한 표시 결과만 검증한다.

## 관련

- [minglit_kit bootstrap](../../../lib/src/bootstrap/BLUEDOC.md)
- [minglit_kit test BLUEDOC](../../BLUEDOC.md)

---
_Reviewed: 2026-05-23 00:00_
