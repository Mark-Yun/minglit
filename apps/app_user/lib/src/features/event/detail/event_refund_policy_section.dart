part of 'event_detail_page.dart';

class _RefundPolicySection extends StatelessWidget {
  const _RefundPolicySection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          _buildPolicyRow(context, '이벤트 시작 7일 전', '전액 환불'),
          const SizedBox(height: MinglitSpacing.small),
          _buildPolicyRow(context, '이벤트 시작 3~7일 전', '50% 환불'),
          const SizedBox(height: MinglitSpacing.small),
          _buildPolicyRow(context, '이벤트 시작 3일 이내', '환불 불가'),
          const SizedBox(height: MinglitSpacing.medium),
          Text(
            '자세한 내용은 고객센터로 문의해주세요.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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
          child: Text(
            condition,
            style: theme.textTheme.bodyMedium,
          ),
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
