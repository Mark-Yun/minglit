import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// **Minglit List Tile**
///
/// A unified list tile widget for the Minglit design system.
/// Wraps Material [ListTile] with Minglit design tokens for consistent
/// spacing, colors, and accessibility across the app.
///
/// Supports an optional [avatar] for displaying a [CircleAvatar],
/// custom [leading] / [trailing] widgets, and disabled state.
///
/// {@tool snippet}
/// ```dart
/// MinglitListTile(
///   title: '홍길동',
///   subtitle: '파트너 매니저',
///   avatar: NetworkImage('https://example.com/photo.jpg'),
///   onTap: () => print('tapped'),
/// )
/// ```
/// {@end-tool}
class MinglitListTile extends StatelessWidget {
  /// Creates a list tile with a required [title].
  ///
  /// When [avatar] is provided, a [CircleAvatar] is shown as the leading
  /// widget. If both [avatar] and [leading] are provided, [avatar] takes
  /// precedence.
  const MinglitListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.avatar,
    this.enabled = true,
    super.key,
  });

  /// Primary text displayed in the tile.
  final String title;

  /// Optional secondary text displayed below [title].
  final String? subtitle;

  /// Optional widget displayed before the title.
  /// Ignored when [avatar] is provided.
  final Widget? leading;

  /// Optional widget displayed after the title.
  final Widget? trailing;

  /// Called when the tile is tapped.
  final VoidCallback? onTap;

  /// Optional image for a [CircleAvatar] shown as the leading widget.
  /// Takes precedence over [leading] when provided.
  final ImageProvider? avatar;

  /// Whether the tile is interactive. Defaults to `true`.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveLeading = avatar != null
        ? CircleAvatar(backgroundImage: avatar)
        : leading;

    final titleStyle = theme.textTheme.bodyLarge?.copyWith(
      color: enabled
          ? colorScheme.onSurface
          : colorScheme.onSurface.withValues(alpha: MinglitOpacity.muted),
    );

    final subtitleStyle = theme.textTheme.bodyMedium?.copyWith(
      color: enabled
          ? colorScheme.onSurfaceVariant
          : colorScheme.onSurfaceVariant
              .withValues(alpha: MinglitOpacity.muted),
    );

    return Semantics(
      button: onTap != null && enabled,
      enabled: enabled,
      child: ListTile(
        title: Text(title, style: titleStyle),
        subtitle: subtitle != null
            ? Text(subtitle!, style: subtitleStyle)
            : null,
        leading: effectiveLeading,
        trailing: trailing,
        onTap: enabled ? onTap : null,
        enabled: enabled,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.medium,
          vertical: MinglitSpacing.xsmall,
        ),
        minVerticalPadding: MinglitSpacing.small,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MinglitRadius.small),
        ),
      ),
    );
  }
}
