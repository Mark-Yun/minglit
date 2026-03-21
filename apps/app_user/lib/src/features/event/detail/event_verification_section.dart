part of 'event_detail_page.dart';

class _VerificationSection extends ConsumerWidget {
  const _VerificationSection({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Collect all unique verification IDs from all entry groups
    final allIds =
        (event.entryGroups ?? [])
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
            // Fix #191: MinglitChip → VerificationCard로 변경하여 다른 UI와 룩앤필 통일
            MinglitAsyncValueWidget(
              value: ref.watch(verificationsByIdsProvider(allIds.join(','))),
              data: (verifications) => Column(
                children: verifications
                    .map(
                      (v) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: MinglitSpacing.small,
                        ),
                        // Fix #191: 클릭 시 상세 화면 이동 (임시 스낵바)
                        child: VerificationCard(
                          verification: v,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('구현준비중입니다'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          trailing: Icon(
                            Icons.chevron_right,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              loading: () =>
                  const MinglitSkeleton(height: 72, width: double.infinity),
              error: (e, s) => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}
