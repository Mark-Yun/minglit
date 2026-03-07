part of 'event_detail_page.dart';

class _EntryConditionsSection extends StatelessWidget {
  const _EntryConditionsSection({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entryGroups = event.entryGroups ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '참여 자격',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        if (entryGroups.isEmpty)
          const Text('별도의 참여 제한이 없습니다.')
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
              final showGauge = matchingTickets.isNotEmpty && totalQuantity > 0;

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
                    child: EntryGroupDetail(group: group.toTemplate()),
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
