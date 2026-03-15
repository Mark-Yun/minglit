part of 'event_detail_page.dart';

class _EntryConditionsSection extends ConsumerWidget {
  const _EntryConditionsSection({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entryGroups = event.entryGroups ?? [];
    final countsAsync = ref.watch(
      entryGroupParticipantCountsProvider(event.id),
    );
    final counts = countsAsync.value ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '참여 현황',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        if (entryGroups.isEmpty)
          Text(
            '${event.currentParticipants}명 / ${event.maxParticipants}명',
            style: theme.textTheme.bodyMedium,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entryGroups.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: MinglitSpacing.medium),
            itemBuilder: (context, index) {
              final group = entryGroups[index];
              final matchingTickets = (event.tickets ?? [])
                  .where(
                    (t) =>
                        t.targetEntryGroupIds.isNotEmpty &&
                        t.targetEntryGroupIds.contains(group.id),
                  )
                  .toList();
              final soldCount = matchingTickets.fold<int>(
                0,
                (sum, t) => sum + t.soldCount,
              );
              final totalQuantity = matchingTickets.fold<int>(
                0,
                (sum, t) => sum + t.quantity,
              );
              final showGauge = matchingTickets.isNotEmpty;
              final participantCount = counts[group.id] ?? 0;

              return Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(MinglitSpacing.small),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(MinglitRadius.small),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EntryGroupDetail(
                          group: group.toTemplate(),
                          showVerificationBadges: false,
                        ),
                        const SizedBox(height: MinglitSpacing.xsmall),
                        Text(
                          '$participantCount명 참여',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showGauge)
                    Positioned(
                      top: MinglitSpacing.small,
                      right: MinglitSpacing.small,
                      child: MinglitParticipantGauge(
                        current: soldCount,
                        max: totalQuantity,
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}
