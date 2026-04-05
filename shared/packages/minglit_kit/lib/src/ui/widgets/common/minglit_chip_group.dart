import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// 가로 스크롤 또는 줄바꿈 칩 그룹 레이아웃 위젯.
///
/// [scrollable]이 true면 `ListView.separated` 기반 가로 스크롤,
/// false면 `Wrap` 기반 줄바꿈 레이아웃을 사용합니다.
///
/// 각 칩 사이 간격과 외부 패딩을 자동으로 적용합니다.
// Fix #477: 반복되는 필터 칩 그룹 패턴 통합 — MinglitChipGroup 합성 위젯
class MinglitChipGroup extends StatelessWidget {
  /// Creates a [MinglitChipGroup].
  const MinglitChipGroup({
    required this.children,
    this.height = 40,
    this.spacing = MinglitSpacing.small,
    this.padding = const EdgeInsets.symmetric(
      horizontal: MinglitSpacing.medium,
    ),
    this.scrollable = true,
    super.key,
  });

  /// 칩 위젯 목록.
  final List<Widget> children;

  /// 스크롤 가능 모드일 때 높이. [scrollable]이 false면 무시됩니다.
  final double height;

  /// 칩 간 간격. [scrollable]이 false일 때 Wrap의 spacing과 runSpacing에 적용됩니다.
  final double spacing;

  /// 외부 패딩.
  final EdgeInsets padding;

  /// true: 가로 스크롤 (`ListView.separated`), false: 줄바꿈 (`Wrap`).
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    if (!scrollable) {
      return Padding(
        padding: padding,
        child: Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children,
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: children.length,
        separatorBuilder: (context, index) => SizedBox(width: spacing),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }
}
