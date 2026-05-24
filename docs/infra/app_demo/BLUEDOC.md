# app_demo

`app_user` / `app_partner` 의 **데모 flavor** 인프라. 실제 라우터·뷰·Coordinator 를 그대로 쓰되 Repository 레이어를 in-memory fixture 로 갈아 끼워 **서버 0 연결** 로 부팅·동작하는 APK 를 만든다. emulator-render 워크플로우와 동일 fixture 패키지를 공유한다.

## 왜 있나

영업·투자자 시연 / 스토어 스크린샷 / 신규 입사자 온보딩 등 **백엔드 없이 진짜 앱처럼 동작해야 하는** 시나리오를 위한 별 flavor. 기존 시연용 mock 데이터가 5+ 곳에 산재해 drift 진행 중 — 데모 flavor 신설을 계기로 fixture SSoT 도 통합한다.

## 이정표

| 항목 | 무엇 |
|---|---|
| [`architecture.md`](./architecture.md) | 설계 — 패키지 레이아웃, override 전략, 라우터·뷰 재활용 표, drift 방지 규칙 |
| [`plan.md`](./plan.md) | 단계별 작업 (P0-P8) 체크리스트 + acceptance criteria |
| [`shared/packages/minglit_demo/`](../../../shared/packages/minglit_demo/) | fixture + ProviderScope override 빌더 |
| [`apps/app_user/lib/main_demo.dart`](../../../apps/app_user/lib/main_demo.dart) | 사용자 앱 데모 entry |
| [`apps/app_partner/lib/main_demo.dart`](../../../apps/app_partner/lib/main_demo.dart) | 파트너 앱 데모 entry |
| `apps/*/android/app/src/demo/google-services.json` | demo Android variant 빌드용 non-secret Firebase placeholder |
| `minglit_env/demo/flutter.env` | demo compile-time env (`IS_DEMO=true`, placeholder keys) |
| [`.github/workflows/pr-gate.yml`](../../../.github/workflows/pr-gate.yml) | demo Android debug APK 빌드 gate |

## 핵심 컨벤션

- **데모 ≠ 시나리오 선택 화면**: 실제 라우터 그대로, 자동 로그인된 데모 유저로 부팅. 사용자는 평범하게 네비게이션
- **fixture SSoT**: `shared/packages/minglit_demo/lib/fixtures/` 한 곳. unit test·emulator-render·데모 앱 모두 여기서 import
- **prod 격리**: `Supabase.instance.client` 직접 호출 금지 → `dart-custom-lint` 룰로 강제 (P0)
- **외부 SDK init 가드**: `EnvKeyStore.isDemo` 분기에서 network SDK init 을 skip
- **별도 ApplicationId**: `com.minglit.app_user.demo`, `com.minglit.app_partner.demo` → 실 앱과 나란히 설치

## 관련

- [BLUEDOC 컨벤션](../bluedoc/BLUEDOC.md) — 본 문서가 따르는 진입점 형식
- [apps/app_user/BLUEDOC.md](../../../apps/app_user/BLUEDOC.md) — 데모 flavor 가 얹히는 사용자 앱
- [apps/app_partner/BLUEDOC.md](../../../apps/app_partner/BLUEDOC.md) — 동일, 파트너 앱
- [shared/packages/minglit_kit/BLUEDOC.md](../../../shared/packages/minglit_kit/BLUEDOC.md) — Repository 들이 사는 곳, P0 리팩터 대상
- [apps/app_user/integration_test/mds-emulator-render/BLUEDOC.md](../../../apps/app_user/integration_test/mds-emulator-render/BLUEDOC.md) — fixture 패키지 공동 소비자

---
_Reviewed: 2026-05-24 16:30_
