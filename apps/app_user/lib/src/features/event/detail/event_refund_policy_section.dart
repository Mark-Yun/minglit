part of 'event_detail_page.dart';

// ignore: specify_nonobvious_property_types // autoDispose type
final _refundPolicyProvider = FutureProvider.autoDispose<Map<String, dynamic>?>(
  (ref) {
    return ref.watch(policyRepositoryProvider).getRefundPolicy();
  },
);

class _RefundPolicySection extends ConsumerWidget {
  const _RefundPolicySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final policyAsync = ref.watch(_refundPolicyProvider);

    return Padding(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '환불 정책',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          policyAsync.when(
            data: (policy) => _buildPolicyContent(context, policy),
            loading: () => _buildLoadingContent(context),
            error: (e, st) => _buildPolicyContent(context, null),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyContent(
    BuildContext context,
    Map<String, dynamic>? policy,
  ) {
    final gracePeriodHours =
        (policy?['grace_period_hours'] as num?)?.toInt() ?? 2;
    final cutoffDays = (policy?['cutoff_days'] as num?)?.toInt() ?? 7;

    return Column(
      children: [
        _buildPolicyRow(
          context,
          '결제 후 $gracePeriodHours시간 이내',
          '전액 환불',
        ),
        const SizedBox(height: MinglitSpacing.small),
        _buildPolicyRow(
          context,
          '이벤트 시작 $cutoffDays일 전까지',
          '전액 환불',
        ),
        const SizedBox(height: MinglitSpacing.small),
        _buildPolicyRow(context, '그 외', '환불 불가'),
        const SizedBox(height: MinglitSpacing.medium),
        Text(
          '자세한 내용은 고객센터로 문의해주세요.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingContent(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: MinglitSpacing.small),
          child: Container(
            height: 20,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyRow(
    BuildContext context,
    String condition,
    String policy,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(condition, style: theme.textTheme.bodyMedium),
        ),
        Text(
          policy,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
