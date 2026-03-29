import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// **Minglit Content Card**
///
/// 통일된 카드 스타일을 제공하는 레이아웃 위젯.
/// 내부 패딩, border radius, 배경색, 보더가 일관되게 적용됩니다.
/// [highlighted]가 true이면 primary 색상 보더가 표시됩니다.
class MinglitContentCard extends StatelessWidget {
  /// Creates a content card with unified styling.
  const MinglitContentCard({
    required this.child,
    this.padding,
    this.onTap,
    this.highlighted,
    super.key,
  });

  /// Card content.
  final Widget child;

  /// Internal padding. Defaults to vertical [MinglitSpacing.cardContentV]
  /// and horizontal [MinglitSpacing.medium].
  final EdgeInsetsGeometry? padding;

  /// Optional tap handler.
  final VoidCallback? onTap;

  /// When true, applies a primary-colored border.
  final bool? highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isHighlighted = highlighted ?? false;

    final effectivePadding =
        padding ??
        const EdgeInsets.symmetric(
          vertical: MinglitSpacing.cardContentV,
          horizontal: MinglitSpacing.medium,
        );

    final decoration = BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(MinglitRadius.card),
      border: Border.all(
        color: isHighlighted ? colorScheme.primary : colorScheme.outlineVariant,
      ),
    );

    final card = Container(
      padding: effectivePadding,
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: Ink(
          decoration: decoration,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(MinglitRadius.card),
            child: Padding(padding: effectivePadding, child: child),
          ),
        ),
      );
    }

    return card;
  }
}
