# apps/ — Flutter 앱 공통 아키텍처

`app_user` 와 `app_partner` 가 공유하는 클라이언트 아키텍처. 앱별 고유 패턴은 각 앱의 `architecture.md` 에, 공용 패키지 디테일은 [`shared/packages/minglit_kit/architecture.md`](../shared/packages/minglit_kit/architecture.md) 에.

## 1. Core Tech Stack

| Category | Technology | 이유 |
| --- | --- | --- |
| Framework | Flutter (3.x) | Cross-platform |
| Language | Dart | Type-safe, Null-safe |
| State | **Riverpod** | Compile-safe DI + State |
| Routing | **GoRouter** (Type-safe) | Deep linking, Web 지원, Typed Routes |
| Backend | **Supabase** | Auth, DB(Postgres), Storage, Realtime |
| Architecture | Feature-first + Coordinator | UI / 네비게이션 분리 |

## 2. Key Patterns

### 2.1 Feature-first 구조

모든 코드는 **기능(Feature)** 단위로 응집. `screens/` · `widgets/` 같은 기술적 폴더 대신 도메인 폴더.

```text
apps/<app>/lib/src/features/
├── auth/
├── event/        # app_user 만
├── application/  # app_partner 만 (이벤트 신청 관리)
├── home/
└── ...
```

앱별 features 목록은 각 앱의 BLUEDOC 참고.

### 2.2 Coordinator Pattern

UI 는 "어디로 갈지" 모름. Coordinator 에게 "이 버튼이 눌렸다" 만 알린다.

```dart
// UI 위젯
ref.read(memberCoordinatorProvider).goToDetail(id);

// Coordinator
MemberDetailRoute(id: id).push(context);
```

장점: UI 와 라우팅 로직 완전 분리, 재사용성.

### 2.3 Type-safe Routing

URL 문자열 (`'/login'`) 직접 입력 금지. `go_router_builder` 로 컴파일 타임 검증.

```dart
LoginRoute().go(context);                  // ◯
context.go('/login');                       // ✗ (raw 문자열)
```

라우트 정의는 각 앱의 `lib/src/routing/app_routes.dart` 에.

### 2.4 Repository Pattern

Supabase SDK 를 UI 에서 직접 호출 금지. `Repository` 클래스가 추상화. Repository 는 `minglit_kit` 에 있고 두 앱이 공유.

```dart
ref.read(partnerRepositoryProvider).getMembers(id);
```

Repository 구현 상세는 [minglit_kit/architecture.md](../shared/packages/minglit_kit/architecture.md) 참고.

## 3. Data Flow

```
Repository (Supabase 호출)
    ↓ Future<List<T>>
Provider (@riverpod, 캐싱·상태 관리)
    ↓ AsyncValue<T>
UI (ref.watch, AsyncValue 패턴으로 loading/error 처리)
    ↓ 사용자 액션
Coordinator (routing or state 변경)
```

## 4. Provider Organization

| Provider 타입 | 위치 |
|---|---|
| Shared Repository | `minglit_kit/src/data/repositories/` |
| Shared Logic | `minglit_kit/src/logic/providers/` |
| Feature-local Controller | `apps/<app>/src/features/<feature>/logic/` |
| Coordinator | `apps/<app>/src/features/<feature>/logic/` 또는 feature 루트 |

**kit 으로 가는 조건**:
- 두 앱 모두 필요
- Supabase 테이블 / RPC wrap
- Data model / Repository

**앱 feature 폴더로 가는 조건**:
- 한 앱만 사용
- UI 상태 (controller, form state)
- Coordinator (앱별 라우트에 의존)

상세 가이드라인 + Repository split pattern 은 [minglit_kit/architecture.md § Provider Organization](../shared/packages/minglit_kit/architecture.md) 참고.

## 5. Error Handling

모든 에러는 `minglit_kit` 의 `handleMinglitError` 경유.

| Exception | 처리 |
|---|---|
| `MinglitUserException` | 사용자 친절 메시지 (SnackBar Secondary) |
| `MinglitAuthException` | 인증 오류 |
| `MinglitSystemException` / Unknown | 사용자에겐 안전 메시지, StackTrace 로깅 (SnackBar Error) |

Riverpod 패턴: `AsyncValueMinglitX<T>.showMinglitError(context)` / `guardMinglit()`.

상세는 [minglit_kit/architecture.md](../shared/packages/minglit_kit/architecture.md) § Error Handling 참고.

## 6. Cross-Cutting (공유)

| 항목 | 위치 (모두 `minglit_kit`) |
|---|---|
| Logging | `Log` 클래스 (Log.d/i/w/e). 메모리 1000 줄 이력 유지, release 자동 비활성화 |
| Navigation Observer | `MinglitNavigationObserver` — push/pop/replace 모두 로깅 |
| Configuration | `url_config.dart`, `iamport_config.dart` |
| Location | `location_service.dart` |
| Utility | `age_util`, `refund_calculator`, `ticket_crypto` 등 도메인 특화 |

## 관련

- [BLUEDOC](./BLUEDOC.md) — 앱 폴더 진입점
- [app_user/architecture.md](./app_user/architecture.md) — 유저 앱 고유 (있을 때)
- [app_partner/architecture.md](./app_partner/architecture.md) — 파트너 앱 고유 (권한 redirect 등)
- [minglit_kit/architecture.md](../shared/packages/minglit_kit/architecture.md) — 공용 패키지 디테일
- [docs/architecture/trust-and-verification.md](../docs/architecture/trust-and-verification.md) — 2-layer 신뢰 모델
- [docs/architecture/backend.md](../docs/architecture/backend.md) — Supabase 백엔드
