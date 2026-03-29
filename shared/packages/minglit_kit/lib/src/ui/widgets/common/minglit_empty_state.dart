import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// **Minglit Empty State**
///
/// 데이터가 없는 빈 상태를 통일된 UI로 표시하는 위젯.
/// 아이콘 + 제목 + 부제 + 선택적 CTA 버튼 구성.
class MinglitEmptyState extends StatelessWidget {
  /// Creates an empty state widget with [title] as the primary message.
  const MinglitEmptyState({
    required this.title,
    this.icon = Icons.inbox_outlined,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  /// Icon displayed above the title. Defaults to [Icons.inbox_outlined].
  final IconData icon;

  /// Primary message describing the empty state.
  final String title;

  /// Optional secondary message with additional context.
  final String? subtitle;

  /// Optional action button label (e.g. "새로 만들기").
  /// Button is only shown when both [actionLabel] and [onAction] are provided.
  final String? actionLabel;

  /// Callback for the action button.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.xlarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: MinglitSpacing.medium),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: MinglitSpacing.small),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: MinglitSpacing.large),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
