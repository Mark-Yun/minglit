# Client Architecture

Minglit의 Flutter 클라이언트 아키텍처를 기술한다.
백엔드 인프라는 [Backend Architecture](./backend.md)를 참고.

## 1. Core Tech Stack

| Category | Technology | Reason |
| --- | --- | --- |
| **Framework** | Flutter (3.x) | Cross-platform development |
| **Language** | Dart | Type-safe, Null-safe |
| **State Management** | **Riverpod** | Compile-safe Dependency Injection & State Management |
| **Routing** | **GoRouter** (Type-safe) | Deep linking, Web support, Typed Routes |
| **Backend** | **Supabase** | Auth, DB(Postgres), Storage, Real-time |
| **Architecture** | Feature-first + Coordinator | Decoupled UI & Navigation |

---

## 2. Key Architectural Patterns

### 2.1 Feature-first Structure
모든 코드는 **"기능(Feature)"** 단위로 응집되어 있습니다. `screens`나 `widgets` 같은 기술적 폴더 대신, 도메인 폴더를 사용하여 유지보수성을 높입니다.

```text
minglit_kit/lib/src/features/
├── auth/           # 로그인, 회원가입, OAuth
├── dev/            # 개발 유틸리티 (세션 스위처, 미리보기)
├── iamport/        # 결제 연동 (Iamport SDK 래퍼)
├── loading/        # 글로벌 로딩 오버레이
├── notification/   # 푸시 알림, FCM, 알림 목록/설정
├── search/         # 전문 검색 (PGroonga)
├── social/         # 소셜 기능 (좋아요, 구독, 차단)
├── theme/          # 테마 모드 컨트롤러 (라이트/다크/시스템)
└── verification/   # 본인인증 (Identity Verification) — Iamport V2 기반 실명 인증 화면
```

### 2.2 Coordinator Pattern (Navigation)
**UI는 "어디로 갈지" 모릅니다.** 단순히 Coordinator에게 "이 버튼이 눌렸다"고 알릴 뿐입니다.

*   **UI Widget**: `ref.read(memberCoordinatorProvider).goToDetail(id);`
*   **Coordinator**: `MemberPermissionRoute(id: id).push(context);`
*   **Benefits**: UI와 라우팅 로직의 완벽한 분리, 재사용성 증가.

### 2.3 Type-safe Routing
URL 문자열(`'/login'`)을 직접 입력하지 않습니다. `go_router_builder`를 사용하여 컴파일 타임에 경로와 파라미터를 검증합니다.

*   **Route Class**: `LoginRoute`, `HomeRoute`
*   **Usage**: `LoginRoute().go(context);`

### 2.4 Repository Pattern (Data Access)
Supabase SDK를 직접 UI에서 호출하지 않습니다. `Repository` 클래스가 데이터 접근을 추상화합니다.

*   **Repository**: `PartnerRepository`, `AuthRepository`
*   **Usage**: `ref.read(partnerRepositoryProvider).getMembers(id);`

---

## 3. Data Flow

1.  **Repository**: Supabase에서 데이터를 가져옵니다. (`Future<List<Member>>`)
2.  **Provider**: Repository 데이터를 관리하고 캐싱합니다. (`@riverpod Future<List> memberList(...)`)
3.  **UI**: Provider를 구독(`ref.watch`)하여 화면을 그립니다. 로딩/에러 상태는 `AsyncValue`가 처리합니다.
4.  **Coordinator**: 사용자의 액션(버튼 클릭)을 받아 라우팅이나 상태 변경을 수행합니다.

---

## 4. Design System & UI Infrastructure

### 4.1 Design Tokens
`minglit_design_tokens.dart`에 정의된 `MinglitColors`, 간격(spacing), 타이포그래피를 사용하여 일관된 UI를 유지합니다.

### 4.2 Theme System
`minglit_theme.dart`와 `minglit_component_theme.dart`를 통해 Material theme 및 컴포넌트 테마를 관리합니다. 리치 텍스트를 위해 `minglit_quill_theme.dart`를 제공합니다.

### 4.3 Theme Controller
`theme_controller.dart`는 Riverpod을 기반으로 테마 상태를 관리하며, `SharedPreferences`를 통해 설정을 저장합니다. 라이트, 다크, 시스템 모드를 지원합니다.

### 4.4 Feedback System
`feedback_ext.dart`와 `feedback_components.dart`를 통해 사용자에게 피드백을 제공합니다.
*   `showMinglitSuccess()`, `showMinglitWarning()`, `showMinglitAlert()`, `showMinglitConfirm()`

### 4.5 Global Loading Overlay
`global_loading_controller.dart`와 `minglit_global_loading_overlay.dart`를 사용하여 앱 전역에서 로딩 상태를 표시합니다.

### 4.6 Common UI Widgets
`minglit_kit/lib/src/ui/widgets/`에는 다음과 같은 재사용 가능한 핵심 위젯이 포함되어 있습니다.
*   `minglit_skeleton`, `minglit_image`, `minglit_image_carousel`, `minglit_file_picker`, `minglit_dialog`, `event_card`, `location_map_view`, `minglit_participant_gauge` 등

---

## 5. Trust & Verification Architecture

Minglit은 **"신뢰(Trust)"**를 가장 중요한 자산으로 취급하며, 이를 **2단계 레이어**로 관리합니다. 자세한 내용은 [Trust & Verification](./trust-and-verification.md)을 참고하십시오.

### 5.1 Layer 1: Identity (신원)
*   **정의**: "이 사람은 실존하며, 주장하는 나이/성별이 맞는가?"
*   **데이터**: `user_profiles` 테이블 (`birth_date`, `gender`, `is_verified`).
*   **검증 주체**: 플랫폼 (Iamport 본인인증 API).
*   **특징**: 모든 유저가 갖춰야 할 **기본 자격(Base Layer)**. 파트너 승인이 불필요하며, 즉시 필터링(나이 제한 등)에 사용됩니다.

### 5.2 Layer 2: Qualification (자격)
*   **정의**: "이 사람은 우리 파티에 어울리는가?" (직장, 학력, 자산, 외모 등)
*   **데이터**: `user_verifications` (제출) -> `verification_submissions` (심사) -> `partner_verified_users` (승인).
*   **검증 주체**: 파트너 (사람).
*   **특징**: 특정 파티나 티켓이 요구하는 **추가 자격(Add-on Layer)**.

---

## 6. Provider Organization Guidelines

### 6.1 Where Providers Live

| Provider Type | Location | Example |
|---|---|---|
| **Shared Repository** | `minglit_kit/src/data/repositories/` | `partnerRepositoryProvider`, `eventRepositoryProvider` |
| **Shared Logic** | `minglit_kit/src/logic/providers/` | `supabaseProvider`, `userProfileProvider`, `eventFeedProvider` |
| **Feature-local Controller** | `apps/{app}/src/features/{feature}/logic/` | `purchaseHistoryControllerProvider` |
| **Feature-local Provider** | `apps/{app}/src/features/{feature}/` | `currentPartnerInfoProvider` (in `party_providers.dart`) |
| **Coordinator** | `apps/{app}/src/features/{feature}/logic/` or feature root | `eventCoordinatorProvider`, `adminCoordinatorProvider` |

### 6.2 Decision Criteria

**Put in `minglit_kit` (shared) when:**
- Both `app_user` and `app_partner` need it
- It wraps a Supabase table or RPC call
- It's a data model or repository

**Put in the app's feature folder when:**
- Only one app needs it
- It contains UI state (controllers, form state)
- It's a coordinator (always app-specific, depends on app routes)

### 6.3 Repository Split Pattern

Large repositories (>300 lines) should be split using Dart's `part`/`mixin` pattern:

```dart
// main file: foo_repository.dart
part 'foo_query_repository.dart';
part 'foo_command_repository.dart';

class FooRepository extends _SupabaseFooContextBase
    with _FooQueryRepository, _FooCommandRepository { ... }

// part file: foo_query_repository.dart
part of 'foo_repository.dart';
mixin _FooQueryRepository on _SupabaseFooContext { ... }
```

**References:**
- `event_repository.dart` + `event_repository_queries.dart` + `event_repository_commands.dart`
- `verification_repository.dart` + `verification_query_repository.dart` + `verification_command_repository.dart`
- `partner_repository.dart` + `partner_member_repository.dart` + `partner_application_repository.dart`
- `party_repository.dart` + `party_event_repository.dart` + `party_matching_repository.dart`

### 6.4 Anti-patterns

- **Don't** import from another feature's controller (cross-feature coupling)
  - Bad: `settlement_page.dart` importing `home/partner_dashboard_controller.dart`
  - Fix: Extract shared data models to a common location, create feature-local controllers
- **Don't** place app-specific UI state in `minglit_kit`
- **Don't** create providers without `@riverpod` annotation (prefer code-gen over manual)

---

## 7. Technical Standards

### 7.1 Error Handling
*   **Centralization**: 모든 에러 처리는 `minglit_kit`의 `handleMinglitError`를 통해 수행합니다.
*   **Classification**:
    *   `MinglitUserException`: 사용자에게 보여줄 친절한 메시지 (SnackBar: Secondary Color).
    *   `MinglitAuthException`: 인증 관련 오류 처리.
    *   `MinglitSystemException` / `Unknown`: 사용자에게는 안전한 메시지, 시스템에는 StackTrace 로깅 (SnackBar: Error Color).
*   **Riverpod Integration**: `AsyncValueMinglitX<T>` 확장 메서드의 `showMinglitError(context)`를 사용하여 선언적으로 처리합니다.
*   **Guard Pattern**: `guardMinglit()` 확장을 사용하여 Future를 에러 변환과 함께 래핑합니다.

---

## 8. Cross-Cutting Concerns

### 8.1 Logging
`Log` 클래스를 통해 로깅을 수행합니다. `Log.d()`, `Log.i()`, `Log.w()`, `Log.e()`를 지원하며, 메모리에 최근 1,000줄의 이력을 유지하고 내보낼 수 있습니다. 릴리즈 모드에서는 자동으로 비활성화됩니다.

### 8.2 Navigation Observer
`MinglitNavigationObserver`는 PUSH, POP, REPLACE, REMOVE와 같은 모든 네비게이션 이벤트를 로깅합니다.

### 8.3 Configuration
*   `url_config.dart`: 환경별 URL 설정.
*   `iamport_config.dart`: PG 결제 관련 설정.

### 8.4 Location Service
`location_service.dart`를 통해 지리적 위치 서비스를 통합합니다.

### 8.5 Utility Functions
`age_util.dart`(나이 계산), `refund_calculator.dart`(환불 금액 계산), `ticket_crypto.dart`(티켓 암호화) 등 도메인 특화 유틸리티를 제공합니다.

## Related Documents
- [Backend Architecture](./backend.md) — Supabase 백엔드 인프라
- [Global Event Pipeline](./global-event-pipeline.md) — PGMQ 이벤트 파이프라인
- [Payment Pipeline](./payment-pipeline.md) — 결제/정산 파이프라인
- [Search & Recommendation](./search-and-recommendation.md) — PGroonga + pgvector
- [Trust & Verification](./trust-and-verification.md) — 2-layer 신뢰 모델
