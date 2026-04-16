import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// **Minglit Settings Group**
///
/// A container widget that groups [MinglitSettingsTile]s into a card.
/// Features an optional section header and internal dividers.
class MinglitSettingsGroup extends StatelessWidget {
  /// Creates a [MinglitSettingsGroup].
  const MinglitSettingsGroup({
    required this.children,
    this.header,
    super.key,
  });

  /// The settings tiles to display inside the group.
  final List<Widget> children;

  /// Optional header text displayed above the card.
  final String? header;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Use Material 3 surface container variants
    final cardColor = isDark
        ? colorScheme.surfaceContainerHigh
        : colorScheme.surfaceContainerLowest;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: MinglitSpacing.xsmall,
                bottom: MinglitSpacing.small,
              ),
              child: Text(
                header!.toUpperCase(),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(MinglitRadius.card),
            ),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      indent: 52, // 16 (pad) + 20 (icon) + 16 (gap)
                      color: colorScheme.outlineVariant,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
