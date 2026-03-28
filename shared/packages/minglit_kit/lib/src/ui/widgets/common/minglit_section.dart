import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// **Minglit Section**
///
/// 섹션 헤더 + 콘텐츠를 통일된 구조로 감싸는 레이아웃 위젯.
/// [title]과 [child] 사이에 일관된 간격을 제공하며,
/// 우측에 [trailing] 액션을 배치할 수 있습니다.
class MinglitSection extends StatelessWidget {
  /// Creates a section with a title header and content body.
  const MinglitSection({
    required this.title,
    required this.child,
    this.trailing,
    this.padding,
    this.titleStyle,
    this.spacing,
    super.key,
  });

  /// Section title text.
  final String title;

  /// Content body displayed below the title.
  final Widget child;

  /// Optional trailing widget (e.g. "더보기 >" button).
  final Widget? trailing;

  /// Outer padding. Defaults to [MinglitSpacing.screenEdge] horizontal.
  final EdgeInsetsGeometry? padding;

  /// Title text style override. Defaults to `titleMedium.bold`.
  final TextStyle? titleStyle;

  /// Spacing between title and content. Defaults to [MinglitSpacing.sm].
  final double? spacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePadding =
        padding ??
        const EdgeInsets.symmetric(horizontal: MinglitSpacing.screenEdge);
    final effectiveTitleStyle =
        titleStyle ??
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    final effectiveSpacing = spacing ?? MinglitSpacing.sm;

    return Padding(
      padding: effectivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title, style: effectiveTitleStyle),
              ),
              ?trailing,
            ],
          ),
          SizedBox(height: effectiveSpacing),
          child,
        ],
      ),
    );
  }
}
