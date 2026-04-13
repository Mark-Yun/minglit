import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// Visual variant of [MinglitErrorState].
enum MinglitErrorStateVariant {
  /// Full-page error state — tab or page level.
  /// Shows large icon with retry button. Transparent background.
  fullPage,

  /// Card/section-level error state.
  /// Shows smaller icon. Filled background with rounded corners. No retry CTA.
  card,

  /// Inline error state — form or field level.
  /// No icon. Filled + bordered background. No retry CTA.
  inline,
}

/// **Minglit Error State**
///
/// 에러 발생 시 통일된 UI를 표시하는 위젯.
/// 아이콘 + 제목 + 선택적 상세 메시지 + 재시도 버튼 구성.
///
/// 세 가지 variant를 지원한다:
/// - [MinglitErrorStateVariant.fullPage] (기본): 탭/페이지 수준 에러.
/// - [MinglitErrorStateVariant.card]: 카드/섹션 내 삽입.
/// - [MinglitErrorStateVariant.inline]: 폼/입력 필드 근처.
class MinglitErrorState extends StatelessWidget {
  /// Creates a full-page error state.
  ///
  /// [title] defaults to '오류가 발생했습니다.' if not provided.
  const MinglitErrorState({
    this.title = '오류가 발생했습니다.',
    this.icon = Icons.error_outline,
    this.subtitle,
    this.onRetry,
    this.retryLabel = '다시 시도',
    super.key,
  }) : variant = MinglitErrorStateVariant.fullPage;

  /// Creates a card-level error state (no retry CTA).
  const MinglitErrorState.card({
    this.title = '오류가 발생했습니다.',
    this.icon = Icons.error_outline,
    this.subtitle,
    super.key,
  }) : variant = MinglitErrorStateVariant.card,
       onRetry = null,
       retryLabel = '다시 시도';

  /// Creates an inline error state (no icon, no retry CTA).
  const MinglitErrorState.inline({
    this.title = '오류가 발생했습니다.',
    this.subtitle,
    super.key,
  }) : variant = MinglitErrorStateVariant.inline,
       icon = Icons.error_outline,
       onRetry = null,
       retryLabel = '다시 시도';

  /// Icon displayed above the title.
  /// Ignored when [variant] is [MinglitErrorStateVariant.inline].
  final IconData icon;

  /// Primary error message.
  final String title;

  /// Optional secondary message with error details.
  final String? subtitle;

  /// Callback for the retry button.
  /// Only available in [MinglitErrorStateVariant.fullPage].
  final VoidCallback? onRetry;

  /// Label for the retry button. Defaults to '다시 시도'.
  final String retryLabel;

  /// Visual variant controlling layout and background.
  final MinglitErrorStateVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.xlarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (variant != MinglitErrorStateVariant.inline) ...[
              Icon(
                icon,
                size: variant == MinglitErrorStateVariant.card
                    ? MinglitIconSize.xlarge
                    : 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: MinglitSpacing.medium),
            ],
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
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
            if (variant == MinglitErrorStateVariant.fullPage &&
                onRetry != null) ...[
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

    switch (variant) {
      case MinglitErrorStateVariant.fullPage:
        return content;

      case MinglitErrorStateVariant.card:
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(
              alpha: MinglitOpacity.muted,
            ),
            borderRadius: BorderRadius.circular(MinglitRadius.card),
          ),
          child: content,
        );

      case MinglitErrorStateVariant.inline:
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(
              alpha: MinglitOpacity.muted,
            ),
            border: Border.all(
              color: theme.colorScheme.error.withValues(
                alpha: MinglitOpacity.strong,
              ),
            ),
            borderRadius: BorderRadius.circular(MinglitRadius.card),
          ),
          child: content,
        );
    }
  }
}
