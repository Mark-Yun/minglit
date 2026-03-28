import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// A section divider for separating content areas.
///
/// Use [MinglitSectionDivider.thick] for major section breaks (8px height)
/// and [MinglitSectionDivider.thin] for minor separations (1px height).
class MinglitSectionDivider extends StatelessWidget {
  const MinglitSectionDivider._({required this.isThick, super.key});

  /// Creates a thick section divider (8px, surface color).
  const MinglitSectionDivider.thick({Key? key})
    : this._(isThick: true, key: key);

  /// Creates a thin section divider (1px, divider color).
  const MinglitSectionDivider.thin({Key? key})
    : this._(isThick: false, key: key);

  /// Whether this divider uses the thick (8px) variant.
  final bool isThick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isThick) {
      return Container(
        height: MinglitSpacing.small,
        color: theme.colorScheme.surfaceContainerHighest,
      );
    }

    return Divider(
      height: 1,
      thickness: 1,
      color: theme.dividerColor,
    );
  }
}
