# 디자인 패턴 카탈로그 — 기술 설계

## 개요

기존 `DesignCatalogPage` (16탭, 1253줄)에 **패턴 탭 그룹**을 추가하여 7개 UI 패턴의 라이브 데모 + 상태 토글 + Do/Don't를 제공한다.

### 설계 원칙

1. **기존 파일 분리 우선** — 1253줄 `design_catalog_page.dart`를 먼저 분리한 뒤 패턴 탭 추가
2. **Feature 격리 준수** — 모든 코드는 `minglit_kit/lib/src/features/dev/` 에 위치 (양 앱 공유)
3. **mock 데이터 자급** — 외부 API/Repository 의존 없음. 로컬 mock 데이터로 데모
4. **spec P6 아이콘 크기 수정 반영** — UX 리뷰 피드백: 64px → 32px (`MinglitIconSize.xlarge`)

## 구현 이슈 분할

| 순서 | 제목 | 라벨 | 의존성 | 예상 규모 | 비고 |
|------|------|------|--------|----------|------|
| 1 | refactor: DesignCatalogPage 탭 섹션 파일 분리 | `refactor` | 없음 | M | 1253줄 → 탭별 위젯 파일로 분리 |
| 2 | feat: 패턴 카탈로그 탭 그룹 + 패턴 목록 화면 | `enhancement` | #1 | S | 3-카테고리 패턴 리스트 화면 |
| 3 | feat: P1 상세 페이지 패턴 데모 | `enhancement` | #2 | M | Hero+TabBar+CTA 라이브 프리뷰 + 상태 토글 |
| 4 | feat: P4 카드 레이아웃 패턴 데모 (5변형) | `enhancement` | #2 | M | Image/Transaction/Info/Stats/Selectable 카드 |
| 5 | feat: P6 빈/에러/로딩 상태 패턴 데모 | `enhancement` | #2 | S | 3단계 로딩 + 빈/에러 표준 구조 데모 |
| 6 | feat: P7 Async 래퍼 패턴 데모 | `enhancement` | #2 | S | MinglitAsyncValueWidget 사용법 데모 |
| 7 | feat: P5 결제 플로우 패턴 데모 | `enhancement` | #2 | S | 플로우 다이어그램 + 상태 시뮬레이션 |
| 8 | docs: 03-patterns.md 패턴 카탈로그 반영 | `documentation` | #3~#7 | S | 기존 UX 문서에 상위 패턴 섹션 추가 |

> P2(리스트+필터), P3(폼 위저드)는 와이어프레임이 PM으로부터 보완 예정이므로 이번 스코프에서 제외. 보완 후 후속 이슈로 추가.

## 수정 대상 파일

### 프론트엔드 (minglit_kit)

| 파일 | 변경 내용 |
|------|----------|
| `shared/packages/minglit_kit/lib/src/features/dev/design_catalog_page.dart` | 탭별 위젯을 별도 파일로 추출. TabController를 3그룹(토큰/위젯/패턴) 구조로 변경 |
| `shared/packages/minglit_kit/lib/src/features/dev/catalog_tabs/` (신규 디렉토리) | 기존 16개 탭 위젯 + 패턴 탭 위젯 파일 배치 |
| `shared/packages/minglit_kit/lib/src/features/dev/catalog_tabs/colors_section.dart` | 기존 `_ColorsSection` 추출 (public class) |
| `shared/packages/minglit_kit/lib/src/features/dev/catalog_tabs/typography_section.dart` | 기존 `_TypographySection` 추출 |
| ... (나머지 14개 기존 탭 동일 패턴) | |
| `shared/packages/minglit_kit/lib/src/features/dev/catalog_tabs/pattern_list_section.dart` (신규) | 패턴 카테고리 3개 + 패턴 7개 목록 화면 |
| `shared/packages/minglit_kit/lib/src/features/dev/catalog_tabs/pattern_detail_page.dart` (신규) | 패턴 상세 — 설명/프리뷰/상태토글/Do-Don't 공통 레이아웃 |
| `shared/packages/minglit_kit/lib/src/features/dev/catalog_tabs/patterns/` (신규 디렉토리) | 각 패턴 데모 위젯 |
| `shared/packages/minglit_kit/lib/src/features/dev/catalog_tabs/patterns/detail_page_demo.dart` | P1 상세 페이지 데모 (NestedScrollView + TabBar + 스켈레톤) |
| `shared/packages/minglit_kit/lib/src/features/dev/catalog_tabs/patterns/card_layouts_demo.dart` | P4 카드 5변형 프리뷰 + 상태 토글 |
| `shared/packages/minglit_kit/lib/src/features/dev/catalog_tabs/patterns/data_states_demo.dart` | P6 빈/에러/로딩 3단계 데모 |
| `shared/packages/minglit_kit/lib/src/features/dev/catalog_tabs/patterns/async_wrapper_demo.dart` | P7 MinglitAsyncValueWidget 데모 |
| `shared/packages/minglit_kit/lib/src/features/dev/catalog_tabs/patterns/transaction_flow_demo.dart` | P5 결제/환불 플로우 시뮬레이션 |
| `shared/packages/minglit_kit/lib/src/features/dev/catalog_tabs/patterns/mock_data.dart` (신규) | 패턴 데모용 mock 데이터 (이벤트, 카드, 정산 등) |

### UX 문서

| 파일 | 변경 내용 |
|------|----------|
| `docs/ux/design-system/03-patterns.md` | "상위 레벨 패턴" 섹션 추가 — P1~P7 요약 + 카탈로그 참조 링크 |

### 백엔드

변경 없음. 모든 데이터는 로컬 mock.

## 아키텍처 결정

### 1. 탭 구조: 단일 TabBar vs 그룹 분리

**선택**: 그룹 분리 (토큰 | 위젯 | 패턴)

현재 16탭이 이미 화면을 넘기고 있다. 패턴 7개를 추가하면 23탭이 되어 탐색이 불가능해진다.
3그룹 + 서브탭 구조로 전환하여 탐색성을 확보한다:

```
[토큰 ▼] [위젯 ▼] [패턴 ▼]     ← SegmentedButton 또는 탑레벨 TabBar
  └── Colors | Typo | Spacing ...  ← 서브 TabBar (스크롤)
```

### 2. 파일 분리 전략

**선택**: `catalog_tabs/` 디렉토리 + 탭별 1파일

1253줄 단일 파일에 패턴 코드를 추가하면 2000줄을 넘긴다.
이슈 #1에서 먼저 분리한 뒤, 이후 이슈에서 패턴 탭을 추가한다.

### 3. 패턴 데모의 상태 토글 구현

**선택**: `StatefulWidget` + 로컬 enum 상태

각 패턴 데모에 `SegmentedButton<DemoState>` (data/loading/error/empty)를 배치.
`DemoState` enum으로 전환하며, Riverpod 불필요 (순수 UI 상태).

```dart
enum DemoState { data, loading, error, empty }
```

### 4. P2/P3 스코프 아웃

spec에 P2(리스트+필터)와 P3(폼 위저드) 와이어프레임이 PM 보완 예정으로 명시되어 있음.
기술적으로 구현 가능하지만, 와이어프레임 없이 구현하면 재작업 리스크가 높다.
→ 이번 스코프에서 제외하고 후속 이슈로 분리.

## 리스크 및 대응

| 리스크 | 확률 | 영향 | 대응 |
|--------|------|------|------|
| 기존 16탭 분리 시 import 경로 변경으로 양 앱 빌드 깨짐 | 중 | 중 | `design_catalog_page.dart`에서 re-export 또는 barrel file 제공. 이슈 #1에서 양 앱 빌드 검증 필수 |
| P1 데모의 NestedScrollView + TabBar 중첩이 카탈로그 자체 TabBar와 충돌 | 중 | 저 | P1 데모를 별도 Navigator.push 화면으로 분리 (카탈로그 탭 내부 인라인이 아닌 전체 화면 데모) |
| mock 데이터가 실제 모델 구조와 괴리 | 저 | 저 | spec의 데이터 스키마를 따르되, 실제 Event/Party 모델 import 없이 단순 Map/Named record 사용 |
| P2/P3 와이어프레임 보완이 지연되어 패턴 카탈로그가 불완전하게 릴리스 | 중 | 저 | 패턴 목록에서 P2/P3는 "준비 중" placeholder로 표시. 후속 이슈로 추적 |
