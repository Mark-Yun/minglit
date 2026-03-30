part of 'event_detail_page.dart';

// ignore: specify_nonobvious_property_types // autoDispose type
final _refundPolicyProvider = FutureProvider.autoDispose<Map<String, dynamic>?>(
  (ref) {
    return ref.watch(policyRepositoryProvider).getRefundPolicy();
  },
);

class _RefundPolicySection extends ConsumerWidget {
  const _RefundPolicySection({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final policyAsync = ref.watch(_refundPolicyProvider);

    return Padding(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fix #190: 인포버튼을 타이틀 바로 옆에 배치
          Row(
            children: [
              Text(
                '환불 정책',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: MinglitSpacing.xxsmall),
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: MinglitIconSize.small,
                ),
                tooltip: '환불 정책 상세',
                onPressed: () => _showPolicyDetailSheet(context, policyAsync),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: MinglitSpacing.medium),
          policyAsync.when(
            data: (policy) => _buildSummary(context, policy),
            loading: () => _buildLoadingContent(context),
            error: (e, st) => _buildSummary(context, null),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(
    BuildContext context,
    Map<String, dynamic>? policy,
  ) {
    final theme = Theme.of(context);
    final gracePeriodHours =
        (policy?['grace_period_hours'] as num?)?.toInt() ?? 2;
    final cutoffDays = (policy?['cutoff_days'] as num?)?.toInt() ?? 7;
    final cutoffDate = event.startTime.subtract(Duration(days: cutoffDays));
    final now = DateTime.now();
    // Fix #138: "~까지 환불 가능" 문구와 일치하도록 경계값 포함 비교
    final isCutoffRefundable = !now.isAfter(cutoffDate);
    // Fix #190: 요일 추가, D-day 표시로 날짜 인지성 개선
    final dateFormat = DateFormat('M월 d일 (E) HH시', 'ko_KR');
    // Fix #190: 캘린더 일수 기반 계산 — 시간 무관하게 날짜 단위로 비교
    final daysLeft = DateTime(
      cutoffDate.year,
      cutoffDate.month,
      cutoffDate.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fix #423: cutoff 기한 전이면 날짜 기반 환불 가능 배너 표시
        if (isCutoffRefundable)
          _buildCutoffBanner(theme, dateFormat, cutoffDate, daysLeft),
        // Fix #423: cutoff 기한 경과 시 grace period 환불 안내 (기존 "환불 불가" 오해 방지)
        if (!isCutoffRefundable)
          _buildGracePeriodBanner(theme, gracePeriodHours),
        const SizedBox(height: MinglitSpacing.small),
        Text(
          isCutoffRefundable
              ? '결제 후 $gracePeriodHours시간 이내에도 전액 환불 가능'
              : '이벤트 시작 $cutoffDays일 전 환불 마감',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // Fix #423: cutoff 기한 내 환불 가능 배너
  Widget _buildCutoffBanner(
    ThemeData theme,
    DateFormat dateFormat,
    DateTime cutoffDate,
    int daysLeft,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MinglitSpacing.small),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(MinglitRadius.card),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: MinglitIconSize.small,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: MinglitSpacing.small),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: dateFormat.format(cutoffDate),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const TextSpan(text: '까지 환불 가능'),
                  if (daysLeft >= 0)
                    TextSpan(
                      text: daysLeft == 0 ? ' (오늘)' : ' ($daysLeft일 후)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fix #423: cutoff 경과 후 grace period 환불 안내 배너
  Widget _buildGracePeriodBanner(ThemeData theme, int gracePeriodHours) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MinglitSpacing.small),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(MinglitRadius.card),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            size: MinglitIconSize.small,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: MinglitSpacing.small),
          Expanded(
            child: Text(
              '결제 후 $gracePeriodHours시간 이내 전액 환불 가능',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPolicyDetailSheet(
    BuildContext context,
    AsyncValue<Map<String, dynamic>?> policyAsync,
  ) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) {
          final theme = Theme.of(context);
          final policy = policyAsync.value;
          final gracePeriodHours =
              (policy?['grace_period_hours'] as num?)?.toInt() ?? 2;
          final cutoffDays = (policy?['cutoff_days'] as num?)?.toInt() ?? 7;

          return Padding(
            padding: const EdgeInsets.fromLTRB(
              MinglitSpacing.medium,
              0,
              MinglitSpacing.medium,
              MinglitSpacing.xlarge,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '환불 정책 상세',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: MinglitSpacing.medium),
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
                _buildPolicyRow(
                  context,
                  '그 외',
                  '환불 불가',
                  isRefundable: false,
                ),
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
        },
      ),
    );
  }

  Widget _buildLoadingContent(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => Padding(
          padding: const EdgeInsets.only(
            bottom: MinglitSpacing.small,
          ),
          child: Container(
            height: 20,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(MinglitRadius.small),
            ),
          ),
        ),
      ),
    );
  }

  // Fix #424: 환불 가능은 초록, 불가는 빨강으로 색상 구분하여 의미 전달 개선
  Widget _buildPolicyRow(
    BuildContext context,
    String condition,
    String policy, {
    bool isRefundable = true,
  }) {
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
            color: isRefundable
                ? MinglitColors.success
                : theme.colorScheme.error,
          ),
        ),
      ],
    );
  }
}
