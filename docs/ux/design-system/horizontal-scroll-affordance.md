# Horizontal Scroll Affordance Guide

## Overview
모바일 환경에서 가로 스크롤은 콘텐츠가 더 있음을 시각적으로 알리는 것이 매우 중요합니다. 밍글릿 디자인 시스템은 이를 위해 **Edge Fade(엣지 페이드)**와 **Chevron(셰브론) 인디케이터** 패턴을 사용합니다.

## Design Principles
1. **Implicit Affordance (암시적 제공)**: 콘텐츠가 잘린 모습(cut-off content)을 보여주어 스크롤이 가능함을 암시합니다.
2. **Explicit Indicator (명시적 인디케이터)**: 스크롤 위치에 따라 그라데이션 페이드와 화살표 아이콘을 노출하여 사용자에게 방향성을 제시합니다.
3. **Contextual Visibility (상황에 따른 노출)**:
   - 왼쪽 페이드: 오른쪽으로 스크롤되어 왼쪽에 숨겨진 콘텐츠가 있을 때만 노출.
   - 오른쪽 페이드 + Chevron: 오른쪽에 숨겨진 콘텐츠가 있을 때만 노출.

## Visual Tokens
- **Fade Width**: `MinglitSpacing.medium (16px)`
- **Fade Gradient**: `surface` 컬러에서 `transparent`로의 리니어 그라데이션.
- **Chevron Icon**: `Icons.chevron_right` (Size: 16px)
- **Chevron Color**: `onSurfaceVariant` (Opacity: 40%)

## Implementation (MinglitHorizontalScrollGroup)
`minglit_kit` 패키지의 `MinglitHorizontalScrollGroup` 위젯을 사용하여 가로 스크롤 위젯(ListView, SingleChildScrollView 등)을 감싸면 자동으로 적용됩니다.

### Example
```dart
MinglitHorizontalScrollGroup(
  child: ListView.separated(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: MinglitSpacing.medium),
    itemCount: 10,
    separatorBuilder: (_, __) => const SizedBox(width: MinglitSpacing.small),
    itemBuilder: (_, i) => MyChip(index: i),
  ),
)
```

## Checklist
- [ ] 가로 스크롤 칩 그룹(Filter, Choice 등)에 적용되었는가?
- [ ] 다크 모드에서 `surface` 컬러가 배경과 일치하는가?
- [ ] 스크롤이 끝에 도달했을 때 해당 방향의 페이드가 사라지는가?
