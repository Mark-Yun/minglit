import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// A reusable card-style button for add/create actions.
/// Uses the tertiary (mint/lime) color scheme.
class AddActionCard extends StatelessWidget {
  /// Creates a card-style add action button.
  const AddActionCard({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconData = Icons.add_circle_outline,
    super.key,
  });

  /// The primary label displayed on the card.
  final String title;

  /// Optional secondary label displayed under [title].
  final String? subtitle;

  /// Callback invoked when the card is tapped.
  final VoidCallback onTap;

  /// Icon displayed at the leading edge of the card.
  final IconData iconData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: MinglitAnimation.fast,
      decoration: BoxDecoration(
        color: colorScheme.tertiary.withValues(
          alpha: MinglitOpacity.activeChip,
        ),
        borderRadius: BorderRadius.circular(MinglitRadius.input),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MinglitRadius.input),
        child: Padding(
          padding: const EdgeInsets.all(MinglitSpacing.medium),
          child: Row(
            children: [
              Icon(
                iconData,
                color: colorScheme.tertiary,
                size: MinglitIconSize.small,
              ),
              const SizedBox(width: MinglitSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: MinglitSpacing.xxsmall),
                      Text(
                        subtitle!,
                        style: MinglitTextStyles.infoText(context),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: MinglitSpacing.small),
              Icon(
                Icons.chevron_right,
                color: colorScheme.tertiary.withValues(
                  alpha: MinglitOpacity.separator,
                ),
                size: MinglitIconSize.medium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
