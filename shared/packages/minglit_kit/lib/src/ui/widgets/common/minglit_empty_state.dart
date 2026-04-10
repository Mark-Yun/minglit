import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// Visual variant of [MinglitEmptyState].
enum MinglitEmptyStateVariant {
  /// Full-page empty state — tab or page level.
  /// Shows 48px icon with `outline` color. Transparent background. Optional CTA.
  fullPage,

  /// Card/section-level empty state.
  /// Shows 32px icon with `outlineVariant` color. Filled background with
  /// [MinglitRadius.card] rounding. No CTA.
  card,

  /// Inline placeholder — form or input area.
  /// Icon is hidden. Filled + bordered background. No CTA.
  inline,
}

/// **Minglit Empty State**
///
/// 데이터가 없는 빈 상태를 통일된 UI로 표시하는 위젯.
/// 아이콘 + 제목 + 부제 + 선택적 CTA 버튼 구성.
///
/// 세 가지 variant를 지원한다:
/// - [MinglitEmptyStateVariant.fullPage] (기본): 탭/페이지 수준 빈 상태.
/// - [MinglitEmptyStateVariant.card]: 카드/섹션 내 삽입.
/// - [MinglitEmptyStateVariant.inline]: 폼/입력 플레이스홀더.
///
/// Named constructors [MinglitEmptyState.card] 와 [MinglitEmptyState.inline]을
/// 사용해 variant를 간결하게 지정할 수 있다.
class MinglitEmptyState extends StatelessWidget {
  /// Creates an empty state widget with [title] as the primary message.
  /// Defaults to [MinglitEmptyStateVariant.fullPage].
  const MinglitEmptyState({
    required this.title,
    this.icon = Icons.inbox_outlined,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.variant = MinglitEmptyStateVariant.fullPage,
    super.key,
  });

  /// Creates a card-level empty state (no CTA).
  const MinglitEmptyState.card({
    required this.title,
    this.icon = Icons.inbox_outlined,
    this.subtitle,
    super.key,
  }) : variant = MinglitEmptyStateVariant.card,
       actionLabel = null,
       onAction = null;

  /// Creates an inline placeholder empty state (no icon, no CTA).
  const MinglitEmptyState.inline({
    required this.title,
    this.subtitle,
    super.key,
  }) : variant = MinglitEmptyStateVariant.inline,
       icon = Icons.inbox_outlined,
       actionLabel = null,
       onAction = null;

  /// Icon displayed above the title. Defaults to [Icons.inbox_outlined].
  /// Ignored when [variant] is [MinglitEmptyStateVariant.inline].
  final IconData icon;

  /// Primary message describing the empty state.
  final String title;

  /// Optional secondary message with additional context.
  final String? subtitle;

  /// Optional action button label (e.g. "새로 만들기").
  /// Button is only shown when both [actionLabel] and [onAction] are provided,
  /// and [variant] is [MinglitEmptyStateVariant.fullPage].
  final String? actionLabel;

  /// Callback for the action button.
  final VoidCallback? onAction;

  /// Visual variant controlling layout, icon size, background, and CTA.
  final MinglitEmptyStateVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.xlarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (variant != MinglitEmptyStateVariant.inline) ...[
              Icon(
                icon,
                size: variant == MinglitEmptyStateVariant.card
                    ? MinglitIconSize.xlarge
                    : MinglitIconSize.display,
                color: variant == MinglitEmptyStateVariant.card
                    ? theme.colorScheme.outlineVariant
                    : theme.colorScheme.outline,
              ),
              const SizedBox(height: MinglitSpacing.medium),
            ],
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
            if (variant == MinglitEmptyStateVariant.fullPage &&
                actionLabel != null &&
                onAction != null) ...[
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

    switch (variant) {
      case MinglitEmptyStateVariant.fullPage:
        return content;

      case MinglitEmptyStateVariant.card:
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(MinglitRadius.card),
          ),
          child: content,
        );

      case MinglitEmptyStateVariant.inline:
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: MinglitOpacity.muted,
            ),
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(MinglitRadius.card),
          ),
          child: content,
        );
    }
  }
}
