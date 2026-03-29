import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// **Minglit List Tile**
///
/// 리스트 항목 위젯으로 아바타/아이콘 + 제목/부제 + trailing 구조를 제공합니다.
/// Material [ListTile]을 래핑하여 Minglit 디자인 토큰을 강제합니다.
///
/// {@tool snippet}
/// ```dart
/// MinglitListTile(
///   title: '홍길동',
///   subtitle: '서울특별시',
///   leading: CircleAvatar(child: Icon(Icons.person)),
///   trailing: Icon(Icons.chevron_right),
///   onTap: () {},
/// )
/// ```
/// {@end-tool}
class MinglitListTile extends StatelessWidget {
  /// Creates a list tile with Minglit design tokens.
  const MinglitListTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.enabled = true,
    super.key,
  });

  /// Primary text displayed in the tile.
  final String title;

  /// Optional secondary text below the title.
  final String? subtitle;

  /// Optional leading widget (avatar, icon, etc.).
  final Widget? leading;

  /// Optional trailing widget (icon, badge, etc.).
  final Widget? trailing;

  /// Optional tap handler.
  final VoidCallback? onTap;

  /// Whether the tile is interactive. Defaults to true.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: leading,
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: enabled
                ? colorScheme.onSurface
                : colorScheme.onSurface.withValues(
                    alpha: MinglitOpacity.muted,
                  ),
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: enabled
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurfaceVariant.withValues(
                          alpha: MinglitOpacity.muted,
                        ),
                ),
              )
            : null,
        trailing: trailing,
        onTap: enabled ? onTap : null,
        enabled: enabled,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.medium,
          vertical: MinglitSpacing.xsmall,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MinglitRadius.small),
        ),
        minVerticalPadding: MinglitSpacing.small,
      ),
    );
  }
}
