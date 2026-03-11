part of 'event_detail_page.dart';

class _VerificationSection extends ConsumerWidget {
  const _VerificationSection({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Collect all unique verification IDs from all entry groups
    final allIds = (event.entryGroups ?? [])
        .expand((g) => g.requiredVerificationIds)
        .toSet()
        .toList()
      ..sort();

    return Padding(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '필요 인증',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          if (allIds.isEmpty)
            Text(
              '별도의 인증이 필요하지 않습니다.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            MinglitAsyncValueWidget(
              value: ref.watch(verificationsByIdsProvider(allIds.join(','))),
              data: (verifications) => Wrap(
                spacing: MinglitSpacing.small,
                runSpacing: MinglitSpacing.small,
                children: verifications
                    .map(
                      (v) => MinglitChip(
                        label: v.displayName,
                        icon: Icons.verified_user_outlined,
                      ),
                    )
                    .toList(),
              ),
              loading: () => const MinglitSkeleton(height: 32, width: 80),
              error: (e, s) => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}
