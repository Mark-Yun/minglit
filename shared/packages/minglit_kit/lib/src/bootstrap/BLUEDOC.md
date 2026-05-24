# bootstrap

앱 부팅 중 실행되는 초기화 step 의 공통 정책 계층. 앱별 SDK import 없이 critical / platform / degradable 실패 정책만 제공한다.

## 이정표

| 항목 | 무엇 |
|---|---|
| `minglit_startup_step.dart` | startup step 타입과 critical/platform/degradable factory |
| `minglit_startup_plan.dart` | step 실행 순서, timeout, 실패 전파 정책 |
| `minglit_startup_result.dart` | degraded step 수집 결과 |
| `startup_error_policy.dart` | fatal 여부 판정과 failure 모델 |
| `startup_fatal_error_view.dart` | 앱 진입 전 critical 실패 표시용 기본 UI |
| `bootstrap.dart` | bootstrap public export |

## 핵심 컨벤션

- `minglit_kit` bootstrap 은 app_user/app_partner 를 import 하지 않는다.
- Supabase/Auth/env 같은 필수 초기화는 critical 로 두고 실패를 전파한다.
- Analytics/Map/notification 같은 보조 초기화는 degradable 로 두고 앱 진입을 막지 않는다.
- 앱별 SDK 초기화 함수는 각 앱의 `src/bootstrap/` 에서 주입한다.

## 관련

- [minglit_kit BLUEDOC](../../../BLUEDOC.md)
- [apps/architecture.md](../../../../../../apps/architecture.md)

---
_Reviewed: 2026-05-23 00:00_
