import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// **Minglit Error State**
///
/// 에러 발생 시 통일된 UI를 표시하는 위젯.
/// 아이콘 + 제목 + 선택적 상세 메시지 + 재시도 버튼 구성.
class MinglitErrorState extends StatelessWidget {
  /// Creates an error state widget.
  ///
  /// [title] defaults to '오류가 발생했습니다.' if not provided.
  const MinglitErrorState({
    this.title = '오류가 발생했습니다.',
    this.icon = Icons.error_outline,
    this.subtitle,
    this.onRetry,
    this.retryLabel = '다시 시도',
    super.key,
  });

  /// Icon displayed above the title. Defaults to [Icons.error_outline].
  final IconData icon;

  /// Primary error message.
  final String title;

  /// Optional secondary message with error details.
  final String? subtitle;

  /// Callback for the retry button.
  /// Button is only shown when [onRetry] is provided.
  final VoidCallback? onRetry;

  /// Label for the retry button. Defaults to '다시 시도'.
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.xlarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: MinglitSpacing.medium),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
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
            if (onRetry != null) ...[
              const SizedBox(height: MinglitSpacing.large),
              FilledButton(
                onPressed: onRetry,
                child: Text(retryLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
