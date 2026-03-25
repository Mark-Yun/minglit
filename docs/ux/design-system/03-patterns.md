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
| `selectableCardSubtitle` | `textTheme.bodySmall` | `onSurfaceVariant` 70% alpha, fontSize 11 | :57-63 |
| `selectableCardDescription` | `textTheme.bodySmall` | `onSurfaceVariant` 색상 | :66-71 |
| `infoText` | `textTheme.bodySmall` | `onSurfaceVariant`, fontSize 12 | :74-80 |

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

```
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

```
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

<!-- TODO: 공용 EmptyState 위젯 코드 정의 필요. -->

### 권장 구조

```
[Center]
  [Icon]                 — MinglitIconSize.xlarge (32px), textSecondary 색상
  [Spacing: medium (16px)]
  [Title]                — titleMedium (16px, bold)
  [Spacing: small (8px)]
  [Description]          — bodyMedium (16px), textSecondary
  [Spacing: large (24px)]
  [Action Button]        — OutlinedButton (선택사항)
```

### 현재 사용 사례

- 정산 빈 상태 golden test: `apps/app_partner/test/goldens/settlement_empty_state`

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

```
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

## 관련 문서

- [01-foundation.md](01-foundation.md) -- 디자인 토큰
- [02-components.md](02-components.md) -- 컴포넌트 테마
- [04-navigation.md](04-navigation.md) -- 네비게이션 패턴

---

*소스 파일 변경 시 이 문서도 함께 업데이트합니다.*
