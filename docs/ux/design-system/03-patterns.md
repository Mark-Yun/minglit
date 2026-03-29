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

<!-- TODO: 공용 EmptyState 위젯 코드 정의 필요. -->

### 권장 구조

```text
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
      horizontal: MinglitSpacing.screenEdge, // 20px
    ),
    child: content,
  ),
)
```

- 항상 최상위 화면을 `SafeArea`로 감쌈
- 좌우 패딩: `screenEdge` (20px) — 토스 20dp 표준
- 하단 패딩: 네비게이션 바 높이 고려

---

## 9. Card Layout

카드 내부/외부 간격 패턴입니다.

| 간격 | 토큰 | 값 | 용도 |
| :--- | :--- | :--- | :--- |
| 카드 간 | `cardGap` | 12px | 카드 리스트에서 카드 사이 간격 |
| 카드 내부 세로 | `cardContentV` | 16px | 카드 내부 상하 패딩 |
| 카드 내부 가로 | `screenEdge` | 20px | 카드 내부 좌우 패딩 |
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
| 화면 가장자리 | `screenEdge` | 20px |
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

## 관련 문서

- [01-foundation.md](01-foundation.md) -- 디자인 토큰
- [02-components.md](02-components.md) -- 컴포넌트 테마
- [04-navigation.md](04-navigation.md) -- 네비게이션 패턴

---

*소스 파일 변경 시 이 문서도 함께 업데이트합니다.*
