# Flutter & Riverpod 3.0 Engineering Standard (v2.0)

**Description**: 본 문서는 Flutter 3.x 및 Riverpod 3.0 환경에서 고성능 리액티브 상태 관리와 유지보수 가능한 아키텍처, 그리고 시각적 품질 보증을 위한 기술 정책을 정의합니다. 모든 클라이언트 엔지니어는 본 정책을 설계 및 구현의 절대적 기준으로 삼습니다.

**References**:
*   [Riverpod 3.0: Mutations & Side Effects](https://riverpod.dev/docs/essentials/side_effects)
*   [Flutter Performance: RepaintBoundary & Rasterization](https://docs.flutter.dev/perf/rendering/best-practices)
*   [Alchemist: Visual Regression Testing for Flutter](https://github.com/Betterment/alchemist)
*   [Code with Andrea: Repository Pattern](https://codewithandrea.com/articles/flutter-repository-pattern)
*   [DCM: Flutter-specific Lint Rules](https://dcm.dev/docs/rules/flutter)

---

## 🚀 Section 1: 리액티브 상태 및 사이드 이펙트 정책 (State & Mutations)

### [Rule 1.1] Mutation-First Side Effects
*   **Policy**: 데이터를 변경하는 모든 동작(POST/PATCH/DELETE)은 반드시 **`Mutation` API** (AsyncNotifier 내의 public 메서드)로 구현해야 합니다.
*   **Implementation**: 
    1. **Optimistic UI**: 네트워크 요청 전 `state`를 미리 업데이트하여 즉각적인 피드백을 제공하고, 실패 시 `try-catch`를 통해 이전 상태로 복구(Rollback)합니다.
    2. **Single Source of Truth**: 성공적인 Mutation 이후에는 관련 프로바이더를 직접 수정하지 않고 `ref.invalidate(provider)`를 호출하여 최신 데이터를 다시 불러오도록 강제합니다.
*   **Audit Criteria**: UI 이벤트 핸들러(`onPressed`) 내부에 비즈니스 로직이나 수동 `try-catch`가 포함되어 있는가? (발견 시 Notifier로 이관 권고)

### [Rule 1.2] Granular Reactivity via Leaf Watching
*   **Policy**: `ref.watch`는 반드시 위젯 트리의 가장 하단(Leaf Node)에서 수행되어야 합니다. 거대한 `build` 메서드 상단에서 전체 객체를 구독하는 것을 금지합니다.
*   **Standard**: 성능 최적화를 위해 반드시 `provider.select((s) => s.field)`를 사용하여 특정 필드의 변화에만 반응하도록 설계합니다.

---

## ⚡ Section 2: 렌더링 성능 및 그리기 정책 (Rendering)

### [Rule 2.1] Repaint Isolation (그리기 격리)
*   **Policy**: 빈번하게 업데이트되거나 애니메이션이 포함된 위젯(예: 로더, 커스텀 페인터, 스크롤 리스트)은 반드시 **`RepaintBoundary`**로 감싸야 합니다.
*   **Rationale**: 독립된 디스플레이 리스트(Display List)를 생성하여 화면 전체의 불필요한 재래스터화(Re-rasterization)를 방지합니다. 이는 프레임 드랍(Jank)을 방지하는 핵심 기법입니다.
*   **Audit Criteria**: 16ms 이상의 프레임 렌더링 시간을 유발하는 위젯에 `RepaintBoundary`가 적용되었는가?

### [Rule 2.2] Build Method Purity (빌드 메서드 순수성)
*   **Policy**: `build()` 메서드는 순수 함수(Pure Function)여야 합니다. 메서드 내부에서의 객체 생성(Controller, ScrollController 등) 및 복잡한 연산($O(n)$ 이상)을 엄격히 금지합니다.
*   **Standard**: 모든 고정 위젯은 `const` 생성자를 사용하여 리빌드 시 최적화 도구가 해당 위젯을 건너뛸 수 있도록(Skip) 지원해야 합니다.

---

## 🎨 Section 3: 시각적 품질 및 회복 탄력성 정책 (Visual QA)

### [Rule 3.1] Dual-Golden Testing Requirement
*   **Policy**: 모든 UI 컴포넌트(`minglit_kit`)는 **Alchemist**를 이용한 골든 테스트를 동반해야 합니다.
*   **Standard**:
    1. **Platform Goldens**: 개발자 환경(macOS/Linux)에서 실제 폰트로 렌더링하여 육안 확인.
    2. **CI Goldens**: 플랫폼 독립적인 검증을 위해 `Ahem` 폰트(obscureText: true)를 사용하여 렌더링.
*   **Coverage**: 테마(Light/Dark), 접근성(Text Scale 1.5x/2.0x), 상태(Loading/Error/Empty)를 모두 포함하는 `GoldenTestGroup`을 작성해야 합니다.
*   **Threshold**: 레이아웃 변화를 감지하기 위해 `diffThreshold: 0.005` (0.5%)를 기준으로 삼습니다.

---

## 🛠️ 시니어 리뷰어 체크리스트 (Summary Checklist)

1.  [ ] **State**: 모든 상태 변경이 `Mutation` 패턴을 따르며 낙관적 업데이트 로직이 포함되었는가?
2.  [ ] **Select**: `ref.watch` 시 `.select`를 사용하여 구독 범위를 최소화했는가?
3.  [ ] **Raster**: 무거운 위젯에 `RepaintBoundary`가 적용되었는가?
4.  [ ] **Purity**: `build()` 메서드 내부에 무거운 연산이나 컨트롤러 생성이 없는가?
5.  [ ] **Goldens**: 신규 UI에 대해 CI 통과가 가능한(Headless) 골든 테스트 케이스가 추가되었는가?
