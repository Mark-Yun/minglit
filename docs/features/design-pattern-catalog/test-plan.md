# 디자인 패턴 카탈로그 — 테스트 보강 계획

## 개요

`DesignCatalogPage` 리팩토링(16탭 분리) + 7개 UI 패턴 라이브 데모 추가에 대한 테스트 전략.
모든 코드가 `minglit_kit/lib/src/features/dev/`에 위치하며, 백엔드 변경 없음 (mock 데이터 자급).

**테스트 대상 이슈**: #1~#8 (plan.md 참조)

---

## 계층별 테스트 계획

### Layer 1: Edge Function 테스트 (Deno)

해당 없음 — 백엔드 변경 없음.

### Layer 2: Widget 테스트 (Flutter)

이 피처의 핵심 테스트 계층. 모든 패턴 데모 위젯의 렌더링 + 상태 전환을 검증한다.

| 위젯 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------|-----------|-------------|---------|
| `DesignCatalogPage` (리팩토링 후) | `design_catalog_page_test.dart` | 3그룹 SegmentedButton 전환 (토큰/위젯/패턴), 기존 16탭 정상 렌더링, 양 앱(app_user, app_partner) 빌드 검증 | P1 |
| `PatternListSection` | `pattern_list_section_test.dart` | 3카테고리 렌더링 (레이아웃/콘텐츠/상태), 7개 패턴 항목 표시, P2/P3 "준비 중" placeholder 표시, 패턴 탭 → 상세 네비게이션 | P1 |
| `PatternDetailPage` | `pattern_detail_page_test.dart` | 공통 레이아웃 렌더링 (설명/프리뷰/상태토글/Do-Don't), DemoState enum 전환 (data→loading→error→empty) | P1 |
| `DetailPageDemo` (P1) | `detail_page_demo_test.dart` | Hero+TabBar+CTA 라이브 프리뷰 렌더링, NestedScrollView 중첩 충돌 없음 확인 (별도 화면 push), 4가지 DemoState 전환 시 각 상태 UI 검증, 스켈레톤 로딩 표시 | P1 |
| `CardLayoutsDemo` (P4) | `card_layouts_demo_test.dart` | 5개 카드 변형 렌더링 (Image/Transaction/Info/Stats/Selectable), 각 변형 선택 시 프리뷰 전환, Selectable 카드 선택 상태 토글 | P1 |
| `DataStatesDemo` (P6) | `data_states_demo_test.dart` | 빈/에러/로딩 3단계 표준 구조 렌더링, 아이콘 크기 32px (`MinglitIconSize.xlarge`) 검증 (spec P6 피드백), CTA 버튼 유무 변형, 상태 전환 SegmentedButton 동작 | P1 |
| `AsyncWrapperDemo` (P7) | `async_wrapper_demo_test.dart` | `MinglitAsyncValueWidget` 사용법 데모 렌더링, AsyncValue.loading → shimmer 표시, AsyncValue.error → 에러 위젯 표시, AsyncValue.data → 데이터 위젯 표시 | P2 |
| `TransactionFlowDemo` (P5) | `transaction_flow_demo_test.dart` | 플로우 다이어그램 렌더링, 상태 시뮬레이션 (결제→확인→완료 / 결제→실패), 각 단계별 UI 상태 전환 | P2 |

**테스트 파일 위치**: `shared/packages/minglit_kit/test/src/features/dev/catalog_tabs/`

### Layer 3: 로직 테스트 (순수 함수)

| 함수/클래스 | 테스트 파일 | 테스트 케이스 | 우선순위 |
|------------|-----------|-------------|---------|
| `DemoState` enum | `demo_state_test.dart` | enum 값 4개 존재 (data/loading/error/empty), 기본값 = data | P3 |
| `mock_data.dart` | `mock_data_test.dart` | mock 데이터 구조 유효성 (null 없는 필수 필드), 각 패턴 데모에 필요한 mock이 존재하는지 | P3 |

### Layer 4: Golden 테스트 (시각적 회귀)

| 화면 | 변형 | 골든 파일명 | 우선순위 |
|------|------|-----------|---------|
| `PatternListSection` | 기본 상태 | `pattern_list_section` | P2 |
| `DetailPageDemo` (P1) | data / loading / error / empty | `detail_page_demo_{state}` | P2 |
| `CardLayoutsDemo` (P4) | 5개 변형 각각 | `card_layouts_{variant}` | P2 |
| `DataStatesDemo` (P6) | empty / error / loading | `data_states_{state}` | P1 |
| `AsyncWrapperDemo` (P7) | loading / error / data | `async_wrapper_{state}` | P3 |

**Golden 테스트 규칙**:
- `@Tags(['golden'])` 태그 필수
- CI 골든: `--dart-define=CI=true` (Ahem 폰트 기반)
- 위치: `shared/packages/minglit_kit/test/goldens/`

---

## 이슈별 테스트 매핑

| 이슈 | 제목 | 필수 테스트 | 비고 |
|------|------|-----------|------|
| #1 | refactor: DesignCatalogPage 탭 섹션 파일 분리 | `design_catalog_page_test.dart` — 기존 16탭 렌더링 회귀 없음 + 양 앱 빌드 | 리팩토링이므로 회귀 방지가 핵심 |
| #2 | feat: 패턴 카탈로그 탭 그룹 + 패턴 목록 | `pattern_list_section_test.dart` + golden | 3카테고리 + 7패턴 목록 |
| #3 | feat: P1 상세 페이지 패턴 데모 | `detail_page_demo_test.dart` + golden 4변형 | NestedScrollView 충돌 검증 중요 |
| #4 | feat: P4 카드 레이아웃 패턴 데모 | `card_layouts_demo_test.dart` + golden 5변형 | 5개 변형 모두 렌더링 |
| #5 | feat: P6 빈/에러/로딩 상태 패턴 | `data_states_demo_test.dart` + golden 3변형 | 아이콘 32px 검증 (UX 피드백) |
| #6 | feat: P7 Async 래퍼 패턴 데모 | `async_wrapper_demo_test.dart` | MinglitAsyncValueWidget 통합 |
| #7 | feat: P5 결제 플로우 패턴 데모 | `transaction_flow_demo_test.dart` | 플로우 상태 시뮬레이션 |
| #8 | docs: 03-patterns.md | 테스트 불필요 | 문서 변경만 |

---

## 리스크 기반 테스트 포인트

### 높은 리스크

1. **기존 16탭 분리 시 import 경로 깨짐** (이슈 #1)
   - 양 앱(`app_user`, `app_partner`)에서 `DesignCatalogPage` import 정상 확인
   - 기존 탭(Colors, Typography 등) 렌더링 회귀 없음
   - re-export 또는 barrel file 경로 검증

2. **NestedScrollView 중첩 충돌** (이슈 #3, P1 데모)
   - P1 데모 내부 NestedScrollView + TabBar가 카탈로그 자체 TabBar와 충돌하지 않음
   - 대응: 별도 `Navigator.push` 화면으로 분리 — 이 네비게이션 검증 필수

### 중간 리스크

3. **DemoState 전환 누락** (전 패턴 공통)
   - 모든 패턴 데모에서 `SegmentedButton<DemoState>` 4가지 상태 전환이 UI에 반영되는지
   - 특히 `error` 상태에서 retry CTA 동작

4. **P6 아이콘 크기 64px→32px 미반영** (이슈 #5)
   - UX 리뷰 피드백 반영 검증: `MinglitIconSize.xlarge` = 32px

### 낮은 리스크

5. **mock 데이터 구조 괴리**
   - mock_data.dart의 데이터가 각 데모 위젯에서 정상 소비되는지
   - 실제 모델과 동기화는 불필요 (의도적으로 Map/Record 사용)

---

## 실행 순서

### P1 (필수) — 10건
- `design_catalog_page_test.dart` (탭 분리 회귀)
- `pattern_list_section_test.dart` (패턴 목록)
- `pattern_detail_page_test.dart` (공통 레이아웃)
- `detail_page_demo_test.dart` (P1 상세 페이지)
- `card_layouts_demo_test.dart` (P4 카드 5변형)
- `data_states_demo_test.dart` (P6 빈/에러/로딩)
- Golden: `data_states_{state}` × 3변형
- 양 앱 빌드 검증 (flutter build 성공)

### P2 (권장) — 8건
- `async_wrapper_demo_test.dart` (P7)
- `transaction_flow_demo_test.dart` (P5)
- Golden: `pattern_list_section`
- Golden: `detail_page_demo_{state}` × 4변형
- Golden: `card_layouts_{variant}` × 5변형 (대표 3개 선별 가능)

### P3 (선택) — 4건
- `demo_state_test.dart` (enum 검증)
- `mock_data_test.dart` (mock 데이터 유효성)
- Golden: `async_wrapper_{state}` × 3변형

**총 22건** (P1: 10건, P2: 8건, P3: 4건)
