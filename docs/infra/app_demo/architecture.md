# app_demo — Architecture

`app_user` / `app_partner` 의 **데모 flavor** 설계. 본 문서는 _왜 이렇게 짓는지 + 어떤 부분이 어떻게 굴러가는지_ 의 SSoT. 단계별 작업 분해는 [plan.md](./plan.md) 참고.

## 한 줄 요약

> "**실제 앱과 동일한 라우터·뷰·Coordinator + Repository 레이어만 in-memory fixture 로 갈아낀** flavor APK. Supabase·Firebase·Kakao·IAMport·Statsig 등 외부 네트워크 0 호출. emulator-render 와 같은 fixture 패키지를 공유."

## 비-목표 (해선 안 되는 것)

- **시나리오 선택 화면 없음** — 사용자는 평범한 앱처럼 자유 네비게이션. "데모 시작" / "튜토리얼" 류 진입 화면 만들지 않음
- **Storybook 모드 없음** — 디바이스 안에서 fixture 토글하는 dev-only 화면. 지금 단계에서 미도입 (fixture/override API 만 향후 가능하도록 설계)
- **데모 전용 화면 없음** — 모든 화면은 prod 와 동일
- **prod 빌드에 mock 코드 유출 없음** — 별 패키지 (`minglit_demo`) 격리. prod flavor 빌드 시 의존성 그래프에 미포함

## 비교 — 선택된 안 (B) vs 대안

| 안 | 핵심 | 채택 여부 | 사유 |
|---|---|---|---|
| **A. 새 앱 패키지** (`apps/app_user_demo/`) | 별 Flutter 패키지 신설 | ❌ | 코드/CI/버저닝 부풀음. drift 부담 |
| **B. 새 flavor `demo`** (`lib/main_demo.dart` + Android productFlavor + iOS scheme) | 같은 코드, entry/플레이버만 분리 | ✅ | 별 ApplicationId 가능 (실 앱과 공존), 코드 재활용 최대 |
| **C. dart-define `MOCK=true`** (빌드타임 분기) | flavor 없이 entry 분리 | ❌ | ApplicationId 분리 불가 → 실 앱 위 덮어 설치 |
| **C2/C3. 런타임 토글 / 로그인 화면 버튼** | prod 빌드 안에 mock 코드 박힘 | ❌ | 우연 진입 + 가짜 데이터 prod APK 유출 |

## 전체 구조

```
                     ┌────────────────────────────────────┐
                     │  shared/packages/minglit_demo/     │
                     │  └─ lib/                           │
                     │     ├─ fixtures/   (데이터 SSoT)   │
                     │     └─ overrides/  (Provider 교체) │
                     └──┬───────────────────────┬─────────┘
                        │                       │
              ┌─────────▼─────────┐   ┌─────────▼──────────────────────┐
              │  데모 flavor 앱   │   │  integration_test/             │
              │                   │   │  mds-emulator-render/<screen>/ │
              │  main_demo.dart   │   │  builder.dart                  │
              │  (ProviderScope   │   │  (per-screen 상태 파라미터화)  │
              │   .overrides)     │   │                                │
              └─────────┬─────────┘   └─────────┬──────────────────────┘
                        │                       │
                        │ 같은 라우터·뷰·       │
                        │ Coordinator 트리      │ 같은 라우터·뷰
                        ▼                       ▼
              ┌──────────────────────────────────────────┐
              │  apps/app_user/ + apps/app_partner/      │
              │  (lib/src/ — 변경 없음)                   │
              └──────────────────────────────────────────┘
```

## 패키지 레이아웃 — `minglit_demo`

```
shared/packages/minglit_demo/
├── pubspec.yaml                    # minglit_kit 를 dependency 로
├── BLUEDOC.md
│
└── lib/
    ├── minglit_demo.dart           # barrel export
    │
    ├── fixtures/                   # 순수 데이터 — Freezed 모델 그대로 사용
    │   ├── demo_user.dart
    │   ├── demo_events.dart
    │   ├── demo_parties.dart
    │   ├── demo_tickets.dart
    │   ├── demo_payments.dart
    │   ├── demo_verifications.dart
    │   ├── demo_settlements.dart   # partner
    │   └── demo_world.dart         # 부팅 기본 "세계" (이벤트 10, 파티 5, 티켓 3, ...)
    │
    └── overrides/
        └── demo_overrides.dart     # demoOverrides({events: N, empty: bool, ...}) → List<Override>
```

**중요**: fixture 는 prod 의 **같은 Freezed 모델** 을 import (`package:minglit_kit/minglit_core.dart`). schema 변경 시 `dart analyze` 가 자동으로 drift 감지.

## 부팅 흐름

### 현재 (prod / dev flavor)

```
main.dart
  → EnvKeyStore.validate()                 // SUPABASE_URL 등 필수 키 검증
  → appStartup()  [blocking Future.wait]
       ├─ Supabase.initialize(...)         // 네트워크 init
       ├─ Firebase.initializeApp(...)      // 네트워크 init
       ├─ Statsig.initialize(...)          // 네트워크 init
       └─ (partner) Kakao.AuthRepository.initialize()
  → runApp(ProviderScope(child: MyApp()))
```

### 데모 flavor

```
main_demo.dart
  → EnvKeyStore.validate()                 // demo env (fake-but-valid 포맷)
  → appStartup(demoMode: true)             // 모든 network init skip (composable refactor 필요 — P3)
  → runApp(
      ProviderScope(
        overrides: demoOverrides(),        // Repository * N + supabaseClientProvider stub
        child: MyApp(),                    // ← 그대로
      ),
    )
```

`MyApp` 안의 라우터·Coordinator·뷰 는 한 줄도 안 바뀜.

## 라우터·뷰 재활용 표

| 레이어 | 재활용도 | 이유 |
|---|---|---|
| Router (`app_router.dart`) | **100%** | redirect 가 `currentUserProvider` 만 봄 → override 만으로 동작 |
| Coordinator | **100%** | `GoRouter` 받아 `context.go()` 만 함 |
| Screen Widget | **100%** | Riverpod 소비자. provider override 면 변경 0 |
| Controller / 비즈니스 Provider | **100%** | Repository 호출 결과만 다름 |
| Repository | **100% (인터페이스)** | demo 가 같은 시그니처 구현 (concrete class 그대로 — interface 추출 안 함) |

## 5% 의 예외 — 외부 의존 위젯

이 표는 _뷰 코드 수정 없이 provider/wrapper 단위로_ 해결.

| 위젯/기능 | 안 되는 이유 | 대응 |
|---|---|---|
| `NetworkImage(supabase_url)` | URL 미존재 → broken image | demo 전용 `MinglitImage.network()` wrapper 또는 public CDN (picsum). **별 PR — P4 직전** |
| Realtime 구독 (`event_realtime_provider` 등) | Supabase 연결 없음 → null stream | demo override 가 빈 `Stream.empty()` 또는 pre-baked Stream 반환 |
| `kakao_map_plugin` (partner) | SDK init 안 함 → 위젯 크래시 | demo 전용 stub map widget (정적 이미지) |
| **IAMport 결제 widget** (B4 검증) | `iamport_flutter` **native plugin** — 결제 진입 시 native 호출 트리거 | **Repository fake + IAMport widget 자체 conditional render skip**. demo flavor 에서 결제 진입 시 IAMport widget 대신 "결제 완료" fake 화면 즉시 표시 |
| WebView 약관/도움말 | 외부 호스트 | 번들 asset HTML 로 대체 |
| FCM push token | Firebase init 안 함 → token null | 어차피 안 뜸. notif 목록만 fixture |
| **`flutter_secure_storage`** (B2 검증) | `secureStorage` provider 가 **`apps/app_user/lib/.../ticket_wallet_repository.dart:10`** — app-local provider | demoOverrides 가 minglit_kit 외에도 **app-local provider** 도 override. in-memory Map 으로 가짜 secure storage 구현 |

## 자동 로그인

데모 flavor 는 **로그인된 상태로 부팅**.

- `demoOverrides()` 가 `currentUserProvider` 와 `authStateProvider` 를 demo 유저로 override
- 로그인 화면은 라우터 redirect 가 트리거 안 함 → 자연스럽게 홈으로
- secure storage 같은 디바이스 상태 의존도 안 함 (provider 단에서 완성)

데모 유저 fixture 는 **"풀 프로비저닝" 가정**:
- 인증 완료, 약관 동의 완료, 온보딩 완료
- 권한 모두 보유 (partner 의 경우 모든 매장 role)
- 결제 수단 등록, 정산 계좌 등록 완료

→ 라우터의 권한/온보딩 redirect 가 모두 통과.

## Fixture 디테일

| 항목 | 결정 |
|---|---|
| **fixture 가 mutable in-memory store** (D4) | demo override 가 단순 `List<Event>` 반환이 아니라 **in-memory mutable container** 보유. 이벤트 신청 시 새 ticket 이 store 에 추가됨 → "내 티켓" 화면 등 즉시 동기화. demo 라도 자연스러운 인터랙션 |
| **FK 일관성** (E1) | `demo_world.dart` 가 ID 매핑 보장. `events[0].partner_id == parties[0].id` 같은 cross-fixture 참조 무결성. 신규 fixture 추가 시 demo_world 에 register 의무 |
| **partner role 모델** (E2) | partner 데모 유저는 **단일 매장 owner role** 보유 (가장 단순). 다중 매장 / 멤버 초대 시연 필요 시 fixture 확장 (P7 이후) |
| **mocktail vs fixture 분리 기준** (E3) | `minglit_demo` 에는 **데이터 (Freezed instance) 만**. `class XMock extends Mock` 류는 **test 안 잔류** (`integration_test/_mocks/`, `test/_mocks/`). 분리 기준: `mocktail` import 여부 |

## 데모 UI 동작 차이 (의도된 작은 fake)

prod 와 시각적으로 같지만 동작이 다른 부분. **사용자 입장에선 똑같이 보이고 똑같이 흘러감 — 단, 모든 mutation 이 in-memory 에만 일어남**.

| 화면/기능 | prod | demo |
|---|---|---|
| **로그아웃 → 로그인 → OAuth 버튼** (G1) | Supabase signOut → 로그인 화면 → 카카오/구글 native dialog | demoOverrides 의 fake AuthRepository — signOut 시 in-memory user clear → 로그인 화면. OAuth 버튼 탭 시 **실 OAuth 미발생, 1초 후 fake 로그인 성공 → 홈** |
| **이벤트 신청** (G2/D4) | EF 호출 → DB 반영 → realtime/refetch 로 타 화면 동기화 | demo store mutate → notify listeners → 타 화면 즉시 반영 |
| **결제** (B4) | IAMport widget → PG → webhook → DB | IAMport widget **render skip**, 즉시 "결제 완료" 화면 transition + 티켓 in-memory 추가 |
| **인증 제출** | OS 픽커 (카메라/파일) — 실 동작. 제출 EF 호출 | OS 픽커 실 동작. 제출 시 "심사중" 상태로 fixture 갱신, 실 EF 호출 0 |
| **푸시 알림** | FCM token 등록, 백그라운드 수신 | token null. 알림 목록은 fixture |

## Drift 방지 (가장 중요)

| 위험 | 대응 | 단계 |
|---|---|---|
| DB schema 변경 시 fixture stale | fixture 가 prod Freezed 모델 import → `dart analyze` 자동 감지 | P1 |
| 새 외부 SDK 추가 시 데모 부팅 무음 실패 | (a) `appStartup()` 컴포저블 분해 — 각 init 함수가 `if (demoMode) return;` 가드 / (b) CI 잡 `flutter build apk --flavor demo` 추가 → 깨지면 PR fail | P3, P8 |
| `Supabase.instance.client` 직접 호출 재발 | `dart-custom-lint` 룰: Repository 외부에서 호출 금지 | **P0 의 0e** |
| Repository 우회 (UI 가 Supabase 직호출) | 같은 lint 룰이 동시에 잡음 | P0 |
| fixture / test mock 데이터 갈라짐 | `minglit_demo` 가 SSoT — test/utils/mocks.dart 등 기존 5+ 소스 흡수 | P1 |

## 미래 확장 포인트

| 가능성 | 지원 여부 | 추가 작업 |
|---|---|---|
| 데모 상태 토글 (`--dart-define=DEMO_STATE=empty`) | ✓ | `demoOverrides(empty: true)` 파라미터 추가 |
| 영업/투자자 자동 시연 (탭 시뮬레이션) | ✓ | 별 entry `main_demo_tour.dart` (선택) |
| App Store 데모 비디오 녹화 | ✓ | 데모 APK + screen recording |
| 신규 입사자 온보딩 모드 | ✓ | 같은 APK |
| 마케팅 LP (`landing_user`) 에 데모 iframe | △ | Flutter web 빌드 + demo flavor 조합. 현재 web 빌드 dev/prod 만 — 신규 작업 필요 |
| Storybook-mode (디바이스 안 fixture 토글) | (의도적 미도입) | fixture/override API 는 지원 가능한 형태로 설계 — 나중 결정 |

## 의존성 경계 (Dependency Rules)

데모 flavor 가 prod 코드 품질을 떨어뜨리지 않도록 **단방향 의존 그래프** 강제. 이 원칙이 깨지면 prod APK 에 mock 코드 유출 / drift / cycle 발생.

### 허용되는 의존 그래프

```
[prod 빌드]
  apps/app_user/lib/main.dart  (entry)
    └→ apps/app_user/lib/src/                  (앱 코드)
         └→ shared/packages/minglit_kit/        (공용 패키지)
              └→ (외부 SDK: supabase_flutter, firebase, ...)

[demo 빌드]
  apps/app_user/lib/main_demo.dart  (entry)
    └→ apps/app_user/lib/src/                  (앱 코드 — 동일, 한 줄도 변경 없음)
    └→ shared/packages/minglit_demo/            (데모 패키지)
         └→ shared/packages/minglit_kit/        (Freezed 모델 reuse — drift 자동 감지)
         └→ flutter_riverpod                    (Override 만 의존)

[test (emulator-render)]
  apps/app_user/integration_test/mds-emulator-render/
    └→ shared/packages/minglit_demo/            (fixture 공동 소비)
    └→ flutter_test, mocktail                   (test 안에만 잔류)
```

### 금지 (자동 검증)

| 금지 | 이유 | 검증 도구 |
|---|---|---|
| **prod 코드** (`lib/main.dart`, `lib/src/`) 가 `minglit_demo` import | prod APK 에 데모 코드 유출 | grep + `flutter build apk --flavor prod` 빌드 그래프 audit |
| **`shared/packages/minglit_kit/`** 가 `minglit_demo` import | 단방향 의존 깨짐 → cycle | grep + `dart pub deps` |
| **`minglit_demo`** 가 `mocktail` / `flutter_test` import | 데모 앱이 test 의존 끌어옴 (prod 트리에 mocktail 박힘) | `pubspec.yaml` audit + dependency_validator |
| `minglit_demo` 가 외부 네트워크 SDK 직접 의존 (`supabase_flutter`, `firebase_*`, `kakao_map_plugin`) | 데모가 SDK init 트리거 가능 | `pubspec.yaml` audit |

### 효율적 리팩토링 — drift 감소가 부수 효과

데모 작업이 prod 베이스를 **시작 시점보다 더 깨끗하게** 남겨야 함. 새 코드 추가보다 **기존 산재 통합** 의 비중이 커야 효율적.

| 리팩토링 | Before (산재/문제) | After (단일/통제) | 건강 효과 |
|---|---|---|---|
| **Repository DI 통일** (P0) | `Supabase.instance.client` 직접 호출 15+ 곳 | 모두 `ref.watch(supabaseClientProvider)` | 단일 진입점 / mock 주입 가능 / lint 강제 |
| **Mock SSoT** (P1) | mock 데이터 5+ 위치 산재, drift 진행 | `minglit_demo/fixtures/` 한 곳 | drift 0 / 신규 화면 비용 단일 |
| **appStartup 분해** (P3) | monolithic `Future.wait` (4-5 init 묶음) | 함수별 분리, 각자 가드 | 신규 SDK 추가 시 데모 격리 자명 / 단위 테스트 가능 |
| **Lint 룰 도입** (P0/0e) | BLUEDOC 의 규약 (강제력 없음) | `dart-custom-lint` 가 PR 시점 차단 | anti-pattern 재발 0 |
| **BLUEDOC drift 정리** (P4) | `dev_main.dart` 라는 존재하지 않는 파일 언급 | 실제 entry 컨벤션 (`main.dart` / `main_demo.dart`) 문서화 | 신규 합류자 혼란 0 |

**원칙 (architectural invariant)**: 데모를 위해 추가된 새 코드보다, **기존에 산재해 있던 문제가 통합·정리되어 사라진 코드**가 더 많아야 한다. 그렇지 않다면 "데모 작업이 prod 를 부풀린 것" — 설계가 잘못된 신호.

## 의도적으로 안 한 것

| 항목 | 사유 |
|---|---|
| Repository **interface** 추출 (`abstract class XRepository`) | concrete class + ProviderScope override 로 충분. premature abstraction |
| Realtime 구독 추상화 (공통 base class) | 스코프 큼, feature 별 stream 변환 미묘하게 다름. 데모만 위해선 과투자 |
| `?? Supabase.instance.client` fallback 제거 | 다른 호출자 (테스트) 가 의존 가능. **P0 후 별 PR** |
| Coordinator 사용 강제 lint | cross-feature import lint 가 비슷한 보호. ROI 낮음 |
| 시나리오 선택 화면 | 사용자 요구사항: "실제 앱과 같은 라우팅" |

## 핵심 의사결정 로그

| 결정 | 사유 |
|---|---|
| flavor B (별 ApplicationId) | 실 앱과 공존 + prod 격리 동시 만족 |
| `minglit_demo` 라는 별 패키지 (vs `minglit_kit/src/mocks/`) | prod 의존성 그래프 격리. mocktail 등 test-only 의존이 prod 트리 안 들어옴 |
| emulator-render 와 fixture 공유 | drift 방지 + fixture 확장 한 번에 양쪽 이득. 단 `_engine/` (Mocktail 의존) 은 test 안에 잔류 |
| 자동 로그인 | 사용자 요구사항. 로그인 화면 시연 필요 시 후속 |
| scenarios 레이어 미도입 | 사용자 요구사항. fixture/override 2 레이어만 |
| Repository DI 통일 (P0) 단독 PR | prod 코드 영향, semantic-equivalent, 작은 단위로 리뷰 안전 |
| 0e lint 룰 P0 에 포함 | drift 방지 핵심. 별 PR 도 가능하지만 P0 의 자연스러운 보호막 |
| 자동 로그인 시 데모 유저 "풀 프로비저닝" | redirect guard 다수를 통과시켜야 함 |

## 영향 받는 / 받지 않는 영역

**영향 받음** (touch):
- `shared/packages/minglit_kit/lib/src/data/repositories/*.dart` (~20개, P0 — provider DI 통일)
- `shared/packages/minglit_kit/lib/src/data/services/bug_report_collector.dart`, `features/social/logic/social_interaction_controller.dart` (P0 — Pattern C)
- `shared/packages/minglit_lints/` (P0 — 0e lint 룰)
- `apps/app_user/lib/main.dart`, `apps/app_partner/lib/main.dart` (P3 — appStartup 분해)
- `apps/app_user/android/app/build.gradle.kts`, `apps/app_partner/android/app/build.gradle.kts` (P4 — demo flavor)
- `apps/app_user/ios/Runner.xcodeproj/`, `apps/app_partner/ios/Runner.xcodeproj/` (P4 — Demo scheme)
- `apps/app_user/test/utils/mocks.dart` + 4개 (P1 — mock 흡수, import 갱신)
- `apps/app_user/integration_test/mds-emulator-render/_mocks/` (P2 — `minglit_demo` 사용으로 전환)
- 기존 BLUEDOC 들 (P4 — `dev_main.dart` drift 정리)

**영향 안 받음** (touch X):
- 모든 Feature 화면 위젯 (`lib/src/features/<feature>/ui/*.dart`)
- 라우터 (`app_router.dart`, `app_routes.dart`)
- Coordinator 들
- pr-gate.yml 의 기존 잡 (P8 에서만 demo 빌드 잡 추가)
- Supabase migration / Edge Functions
- 백엔드 코드 일체

## 관련

- [BLUEDOC](./BLUEDOC.md) — 진입점
- [plan.md](./plan.md) — 단계별 작업
- [apps/architecture.md](../../../apps/architecture.md) — Flutter 공통 아키텍처 (Coordinator, Routing, Data Flow)
- [shared/packages/minglit_kit/lib/src/data/architecture.md](../../../shared/packages/minglit_kit/lib/src/data/architecture.md) — Repository 패턴 SSoT (P0 가 따르는 anti-pattern 정의)
- [apps/app_user/integration_test/mds-emulator-render/architecture.md](../../../apps/app_user/integration_test/mds-emulator-render/architecture.md) — fixture 공동 소비자의 렌더 엔진 설계
