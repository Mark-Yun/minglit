# Flutter 및 Dart 스타일 가이드

## 1. 명명 규칙 (Effective Dart)
- **클래스, 열거형, 타입 정의, 확장:** `UpperCamelCase`를 사용하세요.
- **라이브러리, 패키지, 디렉토리, 소스 파일:** `lowercase_with_underscores`를 사용하세요.
- **변수, 매개변수, 명명된 매개변수:** `lowerCamelCase`를 사용하세요.
- **상수:** `lowerCamelCase`를 사용하세요 (최신 Dart 권장). `SCREAMING_SNAKE_CASE`는 레거시 이유가 있을 때만 사용하세요.
- **비공개 멤버:** 밑줄 `_`로 시작하세요.

## 2. 위젯 모범 사례
- **작은 위젯:** 큰 `build()` 메서드는 더 작고 재사용 가능한 비공개 `Widget` 클래스로 나누세요 (헬퍼 메서드보다 `StatelessWidget` 선호).
- **const 생성자:** 재빌드 시간을 줄이기 위해 가능한 경우 항상 `const` 생성자를 사용하세요.
- **불변성:** 위젯을 불변으로 유지하세요. `StatelessWidget`의 모든 필드에 `final`을 사용하세요.
- **빌드 메서드 로직:** `build()` 메서드는 순수하게 유지하세요. `build()` 내부에서 비용이 많이 드는 연산이나 부수 효과(API 호출 등)를 피하세요.

## 3. 상태 관리 (Riverpod)
- **Provider:** 가능한 경우 함수형 프로바이더(`@riverpod`)를 사용하세요.
- **AsyncValue:** 로딩 및 에러 상태는 항상 `AsyncValue` 패턴을 사용하여 처리하세요.
- **ConsumerWidget:** 프로바이더에 접근하려면 `ConsumerWidget` 또는 `ConsumerStatefulWidget`을 사용하세요.
- **Scoped Providers:** 매개변수화된 프로바이더에는 `.family`를 사용하세요.

## 4. 네비게이션 (GoRouter & Coordinator)
- **타입 안전 라우트:** `TypedGoRoute`와 생성된 라우트 클래스를 사용하세요.
- **코디네이터 패턴:** UI 위젯은 `context.go`를 통해 직접 네비게이션하지 않아야 합니다. `Coordinator` 클래스를 사용하여 라우팅 로직을 처리하세요.
- **파라미터 전달:** 라우트에는 간단한 ID나 원시값만 전달하세요. 복잡한 데이터는 대상 화면의 프로바이더에서 가져오세요.

## 5. 성능 및 최적화
- **RepaintBoundary:** 복잡한 애니메이션이나 자주 업데이트되는 UI의 정적인 부분에는 `RepaintBoundary`를 사용하세요.
- **ListView.builder:** 길거나 무한한 리스트에는 항상 `.builder`를 사용하여 지연 로딩을 활성화하세요.
- **Isolates:** 버벅임(jank)을 방지하기 위해 CPU 집약적인 작업(복잡한 JSON 파싱 등)에는 `compute()`를 사용하세요.

## 6. 프로젝트 구조 (Minglit 특화)
- **기능 우선:** 타입보다는 도메인(예: `lib/src/features/auth`)별로 구성하세요.
- **계층형 아키텍처:** 
  - `Data Layer`: 리포지토리 및 모델.
  - `Logic Layer`: 프로바이더 및 컨트롤러.
  - `UI Layer`: 위젯 및 화면.
- **공용 킷:** 시각적 일관성을 유지하기 위해 공통 컴포넌트는 `minglit_kit`를 사용하세요.

## 7. 에러 핸들링
- `minglit_kit`의 `handleMinglitError(context, e)`를 사용하세요.
- Riverpod 기반 UI 업데이트에는 `AsyncValue.showMinglitError(context)`를 선호하세요.

## 8. 디자인 시스템 및 토큰 사용 (필수)
**"모든 UI 수치는 `minglit_kit`가 제어합니다."**

하드코딩된 값은 디자인 일관성을 해치고 유지보수를 어렵게 만듭니다. 반드시 아래의 지정된 디자인 토큰을 사용하세요.

### ❌ 절대 금지 (Bad)
```dart
// 숫자나 색상을 직접 입력하지 마세요!
Padding(padding: EdgeInsets.all(16.0)); 
Color(0xFF9900FF);
SizedBox(height: 20);
BorderRadius.circular(8.0);
TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
```

### ✅ 권장 (Good)
```dart
// minglit_kit의 토큰을 사용하세요.
Padding(padding: EdgeInsets.all(MinglitSpacing.large)); // 간격
MinglitColors.primary; // 색상
MinglitSpacing.verticalMedium; // 높이 간격 (SizedBox 대용)
MinglitRadius.small; // 모서리 반경
MinglitTextStyles.titleLarge(context); // 텍스트 스타일
```

### 주요 토큰 목록
*   **간격 (Spacing):** `MinglitSpacing.small` (8), `.medium` (16), `.large` (24) ...
*   **반경 (Radius):** `MinglitRadius.small` (4), `.card` (12), `.circle` (999) ...
*   **색상 (Colors):** `MinglitColors.primary`, `.secondary`, `.background` ...
*   **타이포 (Typography):** `MinglitTextStyles` 클래스의 정적 메서드 사용 (context 필요).
