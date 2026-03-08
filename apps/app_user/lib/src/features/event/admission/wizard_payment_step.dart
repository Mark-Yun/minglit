part of 'event_application_wizard_page.dart';

class _PaymentStep extends ConsumerWidget {
  const _PaymentStep({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(eventApplicationControllerProvider(event));
    final ticket = state.selectedTicket;

    if (ticket == null) return const Text('티켓 정보가 없습니다.');

    final formatter = NumberFormat('#,###');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '결제 상세',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        Container(
          padding: const EdgeInsets.all(MinglitSpacing.medium),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(MinglitRadius.small),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(ticket.name),
                  Text('${formatter.format(ticket.price)}원'),
                ],
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '최종 결제 금액',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${formatter.format(ticket.price)}원',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: MinglitSpacing.xlarge),
        Text(
          '• 파트너 심사 반려 시 100% 환불됩니다.\n• 결제 완료 후 심사에는 최대 24시간이 소요될 수 있습니다.',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
