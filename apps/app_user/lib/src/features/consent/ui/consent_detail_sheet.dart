import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

Future<void> showConsentDetailSheet(
  BuildContext context, {
  required ConsentDetailContent content,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ConsentDetailSheet(content: content),
  );
}

class ConsentDetailSheet extends StatelessWidget {
  const ConsentDetailSheet({required this.content, super.key});

  final ConsentDetailContent content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(MinglitRadius.card),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: MinglitSpacing.small),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: MinglitOpacity.muted,
                    ),
                    borderRadius: BorderRadius.circular(MinglitRadius.chip),
                  ),
                ),
                const SizedBox(height: MinglitSpacing.medium),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MinglitSpacing.screenEdge,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(content.title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: MinglitSpacing.xsmall),
                      Text(
                        content.summary,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: MinglitSpacing.medium),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      MinglitSpacing.screenEdge,
                      MinglitSpacing.large,
                      MinglitSpacing.screenEdge,
                      MinglitSpacing.large,
                    ),
                    itemBuilder: (context, index) {
                      final section = content.sections[index];
                      return _ConsentDetailSection(section: section);
                    },
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: MinglitSpacing.medium),
                    itemCount: content.sections.length,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ConsentDetailContent {
  const ConsentDetailContent({
    required this.title,
    required this.summary,
    required this.sections,
  });

  final String title;
  final String summary;
  final List<ConsentDetailSection> sections;
}

class ConsentDetailSection {
  const ConsentDetailSection({
    required this.title,
    required this.items,
    // Fix #1143: PIPA 제22조 제4항 — 중요 항목 강조 표시 의무
    this.emphasized = false,
  });

  final String title;
  final List<String> items;
  final bool emphasized;
}

class _ConsentDetailSection extends StatelessWidget {
  const _ConsentDetailSection({required this.section});

  final ConsentDetailSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Fix #1143: PIPA 강조 섹션 — 좌측 보더 + primaryContainer 배경 + primary 타이틀
    return DecoratedBox(
      decoration: BoxDecoration(
        color: section.emphasized
            ? theme.colorScheme.primaryContainer.withValues(
                alpha: MinglitOpacity.muted,
              )
            : theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: MinglitOpacity.scrimMedium,
              ),
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        border: section.emphasized
            ? Border(
                left: BorderSide(color: theme.colorScheme.primary, width: 3),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: section.emphasized ? theme.colorScheme.primary : null,
              ),
            ),
            const SizedBox(height: MinglitSpacing.small),
            for (final item in section.items) ...[
              Text(
                '• $item',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: section.emphasized ? FontWeight.w600 : null,
                ),
              ),
              const SizedBox(height: MinglitSpacing.xsmall),
            ],
          ],
        ),
      ),
    );
  }
}
