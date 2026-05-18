# minglit_demo

데모 flavor 의 fixture + ProviderScope override SSoT. `app_user` / `app_partner` 의 `main_demo.dart` 와 `integration_test/mds-emulator-render/` 가 공동 소비. 서버 0 연결로 부팅하는 데모 APK 의 데이터 레이어.

## 왜 있나

prod 의 Repository 들이 SupabaseClient 를 통해 실 데이터 가져옴. 데모는 이 Repository 를 Fake 구현체로 교체 (ProviderScope.overrides) 해서 fixture 반환. 같은 fixture 가 emulator-render 의 화면별 캡처에도 쓰임 — drift 0.

## 이정표

| 항목 | 무엇 |
|---|---|
| `lib/fixtures/` | 도메인별 fixture (Freezed 모델 reuse, 정적 데이터 + mutable in-memory store) |
| `lib/overrides/` | ProviderScope override 빌더 (`demoOverrides()` 메인 + 도메인별 sub-files) |
| `lib/overrides/poison.dart` | `PoisonSupabaseClient` — 데모에서 호출되면 loud throw (격리 누락 즉시 발견) |
| `lib/overrides/demo_overrides.dart` | 메인 composer — 양 앱이 import |
| [상위 architecture](../../../docs/infra/app_demo/architecture.md) | 설계 SSoT |

## 핵심 컨벤션

- **Freezed 모델 reuse**: fixture 는 `package:minglit_kit/...` 의 Freezed 모델을 그대로 사용. 별 모델 정의 금지 — schema drift 자동 감지
- **PoisonSupabaseClient**: Fake repository 는 `extends XRepository` 하며 super constructor 에 poison client 주입. 데모에서 미override 메서드 호출 시 loud throw → 격리 누락 즉시 발견
- **demoOverrides() 가 정적 호출**: 인자는 미래 확장용 옵셔널 (`empty?`, `events?`). 현재는 옵션 없이 호출 가능
- **양 앱 동시 지원**: user / partner 둘 다의 모든 Repository 를 cover. fixture 도 양쪽 도메인 (티켓 + 정산 등)
- **mocktail / flutter_test / supabase_flutter 직접 의존 금지** — prod 트리에 박힘. minglit_kit 가 transitively 제공

## 관련

- [docs/infra/app_demo/architecture.md](../../../docs/infra/app_demo/architecture.md) — 데모 flavor 전체 설계
- [docs/infra/app_demo/plan.md](../../../docs/infra/app_demo/plan.md) — 단계별 작업 + success metrics
- [minglit_kit/BLUEDOC.md](../minglit_kit/BLUEDOC.md) — fixture 가 reuse 하는 모델·Repository 위치

---
_Reviewed: 2026-05-18 19:30_
