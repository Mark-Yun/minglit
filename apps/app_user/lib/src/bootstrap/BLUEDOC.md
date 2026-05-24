# bootstrap

사용자 앱 부팅 step 조립 계층. 공통 실행 정책은 `minglit_kit/src/bootstrap` 을 쓰고, 앱별 SDK/options 만 여기서 주입한다.

## 이정표

| 항목 | 무엇 |
|---|---|
| `user_startup.dart` | locale, env, Supabase, Firebase, display mode, Statsig 초기화 step |

## 핵심 컨벤션

- Supabase/env validation 은 critical 로 실패를 전파한다.
- Firebase/display mode/Statsig 은 앱 진입을 막지 않는 platform/degradable step 으로 둔다.
- demo flavor 는 네트워크 SDK 초기화를 건너뛰고 `minglit_demo` override 에 의존한다.
- notification deep link/router/app shell 구성은 아직 `main.dart` 에 남긴다.

## 관련

- [app_user BLUEDOC](../../../BLUEDOC.md)
- [minglit_kit bootstrap](../../../../../shared/packages/minglit_kit/lib/src/bootstrap/BLUEDOC.md)

---
_Reviewed: 2026-05-23 00:00_
