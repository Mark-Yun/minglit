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
  const ConsentDetailSheet({
    required this.content,
    super.key,
  });

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
                      alpha: 0.3,
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
                      Text(
                        content.title,
                        style: theme.textTheme.titleLarge,
                      ),
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
  });

  final String title;
  final List<String> items;
}

class _ConsentDetailSection extends StatelessWidget {
  const _ConsentDetailSection({
    required this.section,
  });

  final ConsentDetailSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(MinglitRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: MinglitSpacing.small),
            for (final item in section.items) ...[
              Text(
                '• $item',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: MinglitSpacing.xsmall),
            ],
          ],
        ),
      ),
    );
  }
}
