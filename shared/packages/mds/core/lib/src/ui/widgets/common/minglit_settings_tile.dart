import 'package:flutter/material.dart';
import 'package:mds/mds.dart';

/// Trailing widget types for [MinglitSettingsTile].
enum SettingsTileTrailing {
  /// Chevron icon for navigation.
  navigation,

  /// Switch for on/off toggle.
  toggle,

  /// Text value for read-only information.
  value,

  /// No trailing widget.
  none,
}

/// **Minglit Settings Tile**
///
/// A compact list tile designed specifically for settings and my-page screens.
/// Follows the "layered trust system" design for high information density.
///
/// Features:
/// - Minimum height of 48px (1-line). When [subtitle] is provided the row
///   grows naturally — vertical padding stays fixed at `MinglitSpacing.sm`
///   (12px) so the second line is not cramped.
/// - Support for icon, title, and optional subtitle.
/// - Built-in trailing variants: [SettingsTileTrailing.navigation],
///   [SettingsTileTrailing.toggle], [SettingsTileTrailing.value].
/// - Destructive mode for logout or delete actions.
class MinglitSettingsTile extends StatelessWidget {
  /// Creates a [MinglitSettingsTile].
  const MinglitSettingsTile({
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing = SettingsTileTrailing.navigation,
    this.trailingValue,
    this.onTap,
    this.toggleValue = false,
    this.onToggleChanged,
    this.destructive = false,
    this.enabled = true,
    this.subtitleColor,
    this.iconColor,
    super.key,
  });

  /// The primary label of the tile.
  final String title;

  /// Optional leading icon.
  final IconData? leading;

  /// Optional secondary text displayed below [title].
  /// Usually shows the current value (e.g. "System", "On").
  final String? subtitle;

  /// Optional override for the subtitle text color.
  /// Ignored when [destructive] is true.
  final Color? subtitleColor;

  /// Optional override for the leading icon color.
  /// Ignored when [destructive] is true.
  final Color? iconColor;

  /// The type of trailing widget to display.
  final SettingsTileTrailing trailing;

  /// Required if [trailing] is [SettingsTileTrailing.value].
  final String? trailingValue;

  /// Called when the tile is tapped.
  final VoidCallback? onTap;

  /// Required if [trailing] is [SettingsTileTrailing.toggle].
  final bool toggleValue;

  /// Called when the toggle value changes.
  final ValueChanged<bool>? onToggleChanged;

  /// Whether this action is destructive (e.g. logout).
  /// Changes text and icon color to `colorScheme.error`.
  final bool destructive;

  /// Whether the tile is interactive.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final baseColor = destructive ? colorScheme.error : colorScheme.onSurface;
    final secondaryColor = destructive
        ? colorScheme.error.withValues(alpha: MinglitOpacity.highEmphasis)
        : colorScheme.onSurfaceVariant;

    final titleStyle = theme.textTheme.bodyMedium?.copyWith(
      color: enabled
          ? baseColor
          : baseColor.withValues(alpha: MinglitOpacity.muted),
    );

    final resolvedSubtitleColor =
        (!destructive && subtitleColor != null) ? subtitleColor! : secondaryColor;
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: enabled
          ? resolvedSubtitleColor
          : resolvedSubtitleColor.withValues(alpha: MinglitOpacity.muted),
    );

    Widget? leadingWidget;
    if (leading != null) {
      final resolvedIconColor =
          (!destructive && iconColor != null) ? iconColor! : secondaryColor;
      leadingWidget = Icon(
        leading,
        size: MinglitIconSize.small,
        color: enabled
            ? resolvedIconColor
            : resolvedIconColor.withValues(alpha: MinglitOpacity.muted),
      );
    }

    Widget? trailingWidget;
    switch (trailing) {
      case SettingsTileTrailing.navigation:
        trailingWidget = Icon(
          Icons.chevron_right,
          size: MinglitIconSize.small,
          color: colorScheme.onSurfaceVariant,
        );
      case SettingsTileTrailing.toggle:
        trailingWidget = SizedBox(
          height: 24,
          child: Switch.adaptive(
            value: toggleValue,
            onChanged: enabled ? onToggleChanged : null,
            activeTrackColor: colorScheme.primary,
          ),
        );
      case SettingsTileTrailing.value:
        if (trailingValue != null) {
          trailingWidget = Text(
            trailingValue!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          );
        }
      case SettingsTileTrailing.none:
        trailingWidget = null;
    }

    return InkWell(
      onTap: (enabled && (trailing != SettingsTileTrailing.toggle))
          ? onTap
          : null,
      child: Container(
        // 1줄(title만)일 때는 minHeight 48이 발동해 그대로 48px.
        // 2줄(title + subtitle)일 때는 vertical padding이 고정이라
        // 자연스럽게 ~58로 자란다 — 두 번째 줄이 답답하지 않도록.
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.medium,
          vertical: MinglitSpacing.sm,
        ),
        child: Row(
          children: [
            if (leadingWidget != null) ...[
              leadingWidget,
              const SizedBox(width: MinglitSpacing.medium),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: titleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: subtitleStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (trailingWidget != null) ...[
              const SizedBox(width: MinglitSpacing.small),
              trailingWidget,
            ],
          ],
        ),
      ),
    );
  }
}
