# 03. Patterns — UI 패턴

밍릿 앱에서 반복 사용되는 표준 UI 패턴입니다.

**유틸리티 소스**: `shared/packages/minglit_kit/lib/src/theme/minglit_design_utils.dart`

---

## 1. Selectable Card

선택 가능한 카드 패턴입니다. 선택/미선택 상태에 따라 배경색, 테두리, 그림자가 변합니다.

**소스**: `minglit_design_utils.dart:25-42` (`MinglitDecorations.selectableCard`)

| 상태 | 배경색 | 테두리 | 그림자 | 라인 |
| :--- | :--- | :--- | :--- | :--- |
| 미선택 | `theme.cardColor` | `colorScheme.outlineVariant` | 없음 | :36-38 |
| 선택 | `accentColor` 5% alpha | `colorScheme.secondary` | blurRadius 8, offset (0,4), accentColor 10% alpha | :36-39 |

### Selectable Card 텍스트 스타일

**소스**: `minglit_design_utils.dart:45-82` (`MinglitTextStyles`)

| 스타일 | 기반 | 변형 | 라인 |
| :--- | :--- | :--- | :--- |
| `selectableCardTitle` | `textTheme.titleSmall` | 선택 시 `colorScheme.secondary` 색상 | :47-54 |
| `selectableCardSubtitle` | `textTheme.labelSmall` | `onSurfaceVariant` 70% alpha (Fix #474: bodySmall → labelSmall, 이미 11px) | :57-63 |
| `selectableCardDescription` | `textTheme.bodySmall` | `onSurfaceVariant` 색상 | :66-71 |
| `infoText` | `textTheme.bodySmall` | `onSurfaceVariant` (bodySmall = 13px, Fix #568 이후) | :74-80 |

### Shadow / Border 프리셋

| 클래스 | 메서드 | 설명 | 라인 |
| :--- | :--- | :--- | :--- |
| `MinglitShadows` | `cardSelected(Color)` | 선택 카드 그림자 | :4-13 |
| `MinglitBorders` | `card(ColorScheme, {isSelected})` | 카드 테두리 | :16-22 |

---

## 2. List Item

표준 리스트 아이템 레이아웃입니다.

<!-- TODO: 공용 ListItem 위젯/패턴 코드 정의 필요. 현재는 각 피처에서 개별 구현. -->

### 현재 사용 사례

| 위젯 | 파일 | 설명 |
| :--- | :--- | :--- |
| `PartyListItem` | `apps/app_partner/lib/src/features/party/list/widgets/party_list_item.dart` | 파티 목록 아이템 |
| `TicketListItem` | `apps/app_partner/lib/src/features/party/event/widgets/ticket_list_item.dart` | 티켓 목록 아이템 |

### 권장 구조

```text
[Leading Icon/Avatar] [Title + Subtitle] [Trailing Action/Chevron]
      48x48dp            Expanded              IconButton
```

- 최소 높이: 56dp (접근성 터치 영역 48dp + 패딩)
- 구분선: `Divider` (`#E5E7EB`, thickness 1) 또는 `MinglitSpacing.small` 간격
- 패딩: `MinglitSpacing.medium` (16px) 좌우

---

## 3. Form Layout

라벨 + 입력 필드 + 에러 메시지 구조입니다.

### 입력 필드 테마

`InputDecorationTheme`이 전역 적용되므로 별도 스타일 불필요합니다.

**소스**: `minglit_component_theme.dart:73-94`

| 요소 | 값 |
| :--- | :--- |
| 필드 배경 | `MinglitColors.surface` (`#F9FAFB`) |
| 필드 곡률 | `MinglitRadius.input` (12px) |
| 포커스 테두리 | `MinglitColors.primary` (`#9900FF`) 2px |
| 내부 패딩 | `MinglitSpacing.medium` (16px) all |
| 힌트 텍스트 | `MinglitColors.textSecondary` (`#4B5563`) 14px |

### 권장 구조

```text
[Label Text]              — titleSmall (14px, bold)
[Spacing: small (8px)]
[Input Field]             — InputDecoration 전역 테마 적용
[Spacing: xsmall (4px)]
[Error/Helper Text]       — bodySmall, error 색상
[Spacing: medium (16px)]  — 다음 필드까지 간격
```

### 현재 사용 사례

- `PartyLocationDetailInput` (`apps/app_partner/lib/src/features/party/widgets/party_location_detail_input.dart`)
- `PartyContactInput` (`apps/app_partner/lib/src/features/party/widgets/party_contact_input.dart`)
- `TicketForm` (`apps/app_partner/lib/src/features/ticket/widgets/ticket_form.dart`)

---

## 4. Empty State

데이터가 없을 때 표시하는 빈 상태 화면입니다.

**공용 위젯**: `MinglitEmptyState` (`minglit_kit/lib/src/ui/widgets/common/minglit_empty_state.dart`)

### Variants

3가지 variant로 맥락에 맞는 빈 상태를 표시합니다.

#### fullPage (기본)

전체 화면을 차지하는 빈 상태. 탭/페이지 수준에서 사용.

```text
[Center]
  [Padding: xlarge (32px)]
    [Icon]               — MinglitIconSize.display (48px), outline 색상
    [Spacing: medium (16px)]
    [Title]              — titleMedium (16px, bold), onSurface
    [Spacing: small (8px)]
    [Description]        — bodyMedium (16px), onSurfaceVariant
    [Spacing: large (24px)]
    [Action Button]      — FilledButton (선택사항)
```

#### card

카드/섹션 내에 삽입되는 빈 상태. 리스트나 그리드가 비어있을 때 사용.

```text
[Container: surfaceContainerLowest, radius: card (16px)]
  [Padding: large (24px)]
    [Icon]               — MinglitIconSize.xlarge (32px), outlineVariant 색상
    [Spacing: sm (12px)]
    [Text]               — bodyMedium (14px), onSurfaceVariant
```

#### inline

폼/입력 맥락의 플레이스홀더. 아이콘 없이 텍스트만 표시.

```text
[Container: surfaceContainerHighest 30%, border: outlineVariant, radius: card (16px)]
  [Padding: large (24px)]
    [Text]               — bodyMedium (14px), onSurfaceVariant, center
```

### 사용 예시

```dart
// fullPage — CTA 있는 전체 화면
MinglitEmptyState(
  icon: Icons.confirmation_number_outlined,
  title: '아직 티켓이 없어요',
  subtitle: '관심 있는 이벤트를 찾아보세요',
  actionLabel: '이벤트 둘러보기',
  onAction: () => navigateToExplore(),
)

// card — 섹션 내 빈 상태
MinglitEmptyState.card(
  icon: Icons.verified_user_outlined,
  title: '제출한 인증이 없습니다',
)

// inline — 폼 내 플레이스홀더
MinglitEmptyState.inline(
  title: '아직 추가된 입장 그룹이 없습니다',
)
```

### Wireframe

- [empty-state-variants-wireframe.html](../../features/design-pattern-catalog/empty-state-variants-wireframe.html)

---

## 5. Loading State

로딩 중 상태를 표시하는 패턴입니다.

### 공용 위젯

| 위젯 | 소스 | 설명 |
| :--- | :--- | :--- |
| `MinglitSkeleton` | `minglit_kit/lib/src/ui/widgets/common/minglit_skeleton.dart` | 스켈레톤 로딩 |
| `LoadingIndicator` | `minglit_kit/lib/src/ui/widgets/common/loading_indicator.dart` | 공용 로딩 애니메이션 |
| `MinglitGlobalLoadingOverlay` | `minglit_kit/lib/src/features/loading/minglit_global_loading_overlay.dart` | 전역 로딩 오버레이 |
| `MinglitAsyncValueWidget` | `minglit_kit/lib/src/ui/widgets/common/minglit_async_value_widget.dart` | AsyncValue 상태 처리 래퍼 |

### 사용 원칙

- **목록/카드**: `MinglitSkeleton`으로 콘텐츠 영역 플레이스홀더 표시
- **전체 화면 작업** (결제, 제출 등): `MinglitGlobalLoadingOverlay`
- **비동기 데이터**: `MinglitAsyncValueWidget`으로 loading/error/data 3가지 상태 처리

---

## 6. Error State

에러 발생 시 표시하는 패턴입니다.

<!-- TODO: 공용 ErrorState 위젯 코드 정의 필요. -->

### 권장 구조

```text
[Center]
  [Icon]                 — Icons.error_outline, error 색상 (#EF4444)
  [Spacing: medium (16px)]
  [Error Message]        — titleMedium, 원인 설명
  [Spacing: small (8px)]
  [Help Text]            — bodyMedium, textSecondary, 해결 방법 안내
  [Spacing: large (24px)]
  [Retry Button]         — ElevatedButton "다시 시도"
```

### `MinglitAsyncValueWidget` 활용

`MinglitAsyncValueWidget`은 `AsyncValue.error` 상태에서 자동으로 에러 UI를 표시합니다.

---

## 7. Pull to Refresh

새로고침 패턴입니다.

<!-- TODO: 공용 Pull to Refresh 패턴 표준화 필요. -->

### 권장 구현

```dart
RefreshIndicator(
  color: MinglitColors.primary,
  onRefresh: () => ref.refresh(provider.future),
  child: ListView(...),
)
```

- 인디케이터 색상: `MinglitColors.primary` (`#9900FF`)
- `SliverAppBar`와 조합 시 `NestedScrollView` 사용 권장

---

## 8. Screen Layout

표준 화면 레이아웃 패턴입니다.

```dart
SafeArea(
  child: Padding(
    padding: EdgeInsets.symmetric(
      horizontal: MinglitSpacing.screenEdge, // 16px
    ),
    child: content,
  ),
)
```

- 항상 최상위 화면을 `SafeArea`로 감쌈
- 좌우 패딩: `screenEdge` (16px) — Material 16dp 표준
- 하단 패딩: 네비게이션 바 높이 고려

---

## 9. Card Layout

카드 내부/외부 간격 패턴입니다.

| 간격 | 토큰 | 값 | 용도 |
| :--- | :--- | :--- | :--- |
| 카드 간 | `cardGap` | 12px | 카드 리스트에서 카드 사이 간격 |
| 카드 내부 세로 | `cardContentV` | 16px | 카드 내부 상하 패딩 |
| 카드 내부 가로 | `screenEdge` | 16px | 카드 내부 좌우 패딩 |
| 제목-본문 | `titleToBody` | 4px | 제목과 부제/본문 사이 간격 |

```dart
Column(
  children: [
    for (final item in items)
      Padding(
        padding: EdgeInsets.only(bottom: MinglitSpacing.cardGap),
        child: Card(
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: MinglitSpacing.cardContentV,
              horizontal: MinglitSpacing.screenEdge,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: theme.textTheme.titleMedium),
                SizedBox(height: MinglitSpacing.titleToBody),
                Text(item.body, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
  ],
)
```

---

## 10. Section Divider

`MinglitSectionDivider` 위젯으로 콘텐츠 섹션을 구분합니다.

**소스**: `minglit_kit/lib/src/ui/widgets/common/minglit_section_divider.dart`

### Thick (8px)

주요 섹션 구분. 피드/리스트 화면에서 사용.

```dart
MinglitSectionDivider.thick()
// 높이: 8px, 색상: surfaceContainerHighest
```

### Thin (1px)

섹션 내부 경미한 구분.

```dart
MinglitSectionDivider.thin()
// 높이: 1px, 색상: dividerColor
```

### 사용 가이드

| 컨텍스트 | 디바이더 유형 |
| :--- | :--- |
| 주요 피드 섹션 사이 | thick |
| 리스트 아이템 사이 | thin |
| 설정 그룹 사이 | thick |
| 카드 내부 행 구분 | thin |

---

## 11. Information Hierarchy

텍스트 스타일을 4단계로 나누어 일관된 정보 계층을 만듭니다.

| Level | 스타일 | fontSize | fontWeight | height | 색상 | 용도 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `displayLarge` | 32px | bold | 1.25 | `textPrimary` | 페이지 제목, 히어로 텍스트 |
| 2 | `titleLarge` | 20px | bold | 1.4 | `textPrimary` | 섹션 제목, 카드 제목, 다이얼로그 제목 |
| 3 | `bodyMedium` | 16px | normal | 1.5 | `textSecondary` | 본문, 설명, 폼 라벨 |
| 4 | `bodySmall` | 13px | normal | 1.5 | `textSecondary` | 타임스탬프, 메타데이터, 도움말 |

### 확장 스타일

| 스타일 | 크기 | 무게 | height | 색상 | 용도 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `headlineSmall` | 24px | bold | 1.33 | `textPrimary` | 서브 페이지 제목, 대형 카드 헤더 |
| `titleMedium` | 16px | bold | 1.5 | `textPrimary` | 강조 라벨, 탭 제목 |
| `titleSmall` | 14px | bold | 1.43 | `textPrimary` | 소형 섹션 헤더, 칩 라벨 |
| `bodyLarge` | 18px | normal | 1.33 | `textSecondary` | 부제목, 인트로 텍스트 |
| `labelSmall` | 11px | w500 | 1.45 | `textPrimary` | 세부 사항, 뱃지, 카운터 |

---

## 12. Content Density

화면 컨텍스트에 따른 3단계 밀도 가이드입니다.

### 기본 (Default)

대부분의 화면에서 사용.

| 요소 | 토큰 | 값 |
| :--- | :--- | :--- |
| 화면 가장자리 | `screenEdge` | 16px |
| 카드 간격 | `cardGap` | 12px |
| 카드 내부 패딩 | `cardContentV` | 16px |
| 섹션 간격 | `sectionGap` | 40px |

### 밀집 (Compact)

정보 밀도가 높은 화면 (테이블, 설정, 리스트).

| 요소 | 토큰 | 값 |
| :--- | :--- | :--- |
| 화면 가장자리 | `medium` | 16px |
| 아이템 간격 | `small` | 8px |
| 아이템 내부 패딩 | `sm` | 12px |
| 섹션 간격 | `large` | 24px |

### 여유 (Relaxed)

마케팅/온보딩 화면.

| 요소 | 토큰 | 값 |
| :--- | :--- | :--- |
| 화면 가장자리 | `large` | 24px |
| 카드 간격 | `medium` | 16px |
| 카드 내부 패딩 | `large` | 24px |
| 섹션 간격 | `xxxlarge` | 64px |

---

## 13. 상위 레벨 패턴 (Design Pattern Catalog)

밍릿 앱에서 반복 등장하는 고수준 UI 패턴 7개를 정의합니다. 각 패턴은 `DesignCatalogPage > 패턴` 탭에서 라이브 데모로 확인할 수 있습니다.

> 소스: `shared/packages/minglit_kit/lib/src/features/dev/catalog_tabs/patterns/`

| 패턴 ID | 이름 | 용도 | 상태 |
| :--- | :--- | :--- | :--- |
| P1 | 상세 페이지 | Hero + TabBar + 고정 CTA 레이아웃 | 구현 완료 |
| P2 | 리스트 + 필터 | 검색/필터 + 페이지네이션 목록 | 준비 중 |
| P3 | 폼 위저드 | 단계별 입력 + 검증 흐름 | 준비 중 |
| P4 | 카드 레이아웃 | Image/Transaction/Info/Stats/Selectable 5변형 | 구현 완료 |
| P5 | 결제 플로우 | 결제→확인→완료/실패 + 환불 서브플로우 | 구현 완료 |
| P6 | 빈/에러/로딩 상태 | 3단계 로딩 + 빈/에러 표준 구조 | 구현 완료 |
| P7 | Async 래퍼 | `MinglitAsyncValueWidget` 활용 패턴 | 구현 완료 |

---

### P1 — 상세 페이지 패턴

**용도**: 이벤트/파티 상세 등 Hero 이미지 + TabBar + 고정 CTA가 필요한 화면

**구성 컴포넌트**:
- `NestedScrollView` + `SliverAppBar` (Hero 이미지 영역)
- `TabBar` + `TabBarView` (내용 분탭)
- 하단 고정 `FilledButton` CTA

**상태 변형**: `data` / `loading` (스켈레톤) / `error` / `empty`

**데모 소스**: `catalog_tabs/patterns/detail_page_demo.dart`

---

### P2 — 리스트 + 필터 패턴 *(준비 중)*

**용도**: 검색 + 필터 + 페이지네이션 목록 화면 (예: 이벤트 탐색, 파트너 목록)

> 와이어프레임 보완 후 후속 이슈로 구현 예정.

---

### P3 — 폼 위저드 패턴 *(준비 중)*

**용도**: 다단계 입력 흐름 (예: 이벤트 생성, 프로필 설정)

> 와이어프레임 보완 후 후속 이슈로 구현 예정.

---

### P4 — 카드 레이아웃 패턴

**용도**: 콘텐츠 유형별 카드 선택 기준 제공

**구성 컴포넌트 (5변형)**:

| 변형 | 용도 | 핵심 구성 |
| :--- | :--- | :--- |
| Image | 이벤트/파티 썸네일 카드 | 16:9 이미지 + 그라데이션 + 정보 |
| Transaction | 결제/거래 내역 카드 | 날짜 + 상태 배지 + 썸네일 + 금액 |
| Info | 정산/요약 정보 카드 | 라벨 + 금액(헤드라인) + 상태 배지 |
| Stats | 통계/지표 카드 | 라벨 + 수치 + 증감률 |
| Selectable | 선택 가능 카드 | 토글 테두리 + 배경 틴트 |

**상태 변형**: `data` / `loading` (스켈레톤) / `error` / `empty`

**카드 공통 토큰**:
- 반경: `MinglitRadius.card` (16px)
- 간격: `MinglitSpacing.cardGap` (12px)
- 내부 패딩: `MinglitSpacing.cardContentV` (16px)
- 배경: `MinglitColors.surface` (#F9FAFB)
- elevation: 0 (flat)

**데모 소스**: `catalog_tabs/patterns/card_layouts_demo.dart`

---

### P5 — 결제 플로우 패턴

**용도**: 결제/환불 단계별 UI 상태 전환 시뮬레이션

**결제 플로우**: 확인 → 처리 중 → 성공 / 실패

**환불 서브플로우**: 취소 요청 → 환불 계산 → 처리 중 → 완료

**구성 컴포넌트**:
- 주문 요약 카드 (확인 단계)
- `CircularProgressIndicator` + 안내 텍스트 (처리 중)
- 성공/실패 아이콘 + 결과 화면

**데모 소스**: `catalog_tabs/patterns/transaction_flow_demo.dart`

---

### P6 — 빈/에러/로딩 상태 패턴

**용도**: 모든 데이터 표시 화면에 적용하는 표준 상태 처리 구조

**로딩 3단계**:

| 단계 | 컴포넌트 | 용도 |
| :--- | :--- | :--- |
| 인라인 | `CircularProgressIndicator` | 버튼/소형 액션 로딩 |
| 콘텐츠 | `MinglitSkeleton` | 리스트/카드 콘텐츠 로딩 |
| 전체화면 | `MinglitGlobalLoadingOverlay` | 화면 전체 블로킹 로딩 |

**빈 상태 표준 구조**:
- 아이콘 32px (`MinglitIconSize.xlarge`) + 제목 + 설명 + CTA 버튼

**에러 상태 표준 구조**:
- `Icons.error_outline` 32px + 제목 + 설명 + "다시 시도" 버튼

> Fix #715 UX 리뷰 피드백: 아이콘 크기 64px → 32px

**데모 소스**: `catalog_tabs/patterns/data_states_demo.dart`

---

### P7 — Async 래퍼 패턴

**용도**: 비동기 데이터 로드 시 `MinglitAsyncValueWidget`을 활용하는 표준 패턴

**3가지 AsyncValue 상태**:
- `AsyncValue.loading()` → `MinglitSkeleton` shimmer
- `AsyncValue.error()` → 에러 위젯 + 재시도
- `AsyncValue.data()` → 데이터 위젯 표시

**Do / Don't**:

| Do ✅ | Don't ❌ |
| :--- | :--- |
| `MinglitAsyncValueWidget` 사용 | 수동 `setState` + `_isLoading` 플래그 |
| 상태 케이스를 컴파일 타임에 강제 처리 | 런타임 조건분기 누락 가능성 |

**데모 소스**: `catalog_tabs/patterns/async_wrapper_demo.dart`

---

## 관련 문서

- [01-foundation.md](01-foundation.md) -- 디자인 토큰
- [02-components.md](02-components.md) -- 컴포넌트 테마
- [04-navigation.md](04-navigation.md) -- 네비게이션 패턴

---

*소스 파일 변경 시 이 문서도 함께 업데이트합니다.*
