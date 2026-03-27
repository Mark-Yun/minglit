part of 'event_detail_page.dart';

class _BottomTicketBar extends ConsumerWidget {
  const _BottomTicketBar({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final admissionAsync = ref.watch(eventAdmissionControllerProvider(event));

    final lowestPrice = event.tickets?.fold<int?>(
      null,
      (min, t) => min == null || t.price < min ? t.price : min,
    );

    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('최저가', style: theme.textTheme.labelSmall),
                Text(
                  lowestPrice != null
                      ? '${NumberFormat('#,###').format(lowestPrice)}원~'
                      : '가격 미정',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(width: MinglitSpacing.large),
            Expanded(
              child: MinglitAsyncValueWidget(
                value: admissionAsync,
                data: (state) => _buildActionButton(context, ref, state),
                loading: () => const ElevatedButton(
                  onPressed: null,
                  child: MinglitCircularProgressIndicator(
                    size: 20,
                  ),
                ),
                error: (e, _) => ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.errorContainer,
                  ),
                  child: const Text('오류 발생'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTicketSelection(BuildContext context, WidgetRef ref) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => TicketSelectionSheet(
          event: event,
          onTicketSelected: (eventId, ticketId) {
            ref
                .read(eventCoordinatorProvider)
                .goToApplicationWizard(eventId, ticketId: ticketId);
          },
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    AdmissionState state,
  ) {
    final theme = Theme.of(context);
    final controller = ref.read(
      eventAdmissionControllerProvider(event).notifier,
    );
    final config = controller.buttonConfig(state);
    final onPressed = config.enabled
        ? () => controller.handleAction(
              context: context,
              state: state,
              // Fix #453: ticket feature 직접 참조를 콜백으로 위임
              showTicketSelection: () => _showTicketSelection(context, ref),
            )
        : null;
    Color? backgroundColor;
    switch (config.style) {
      case AdmissionButtonStyle.normal:
        backgroundColor = null;
      case AdmissionButtonStyle.disabled:
        backgroundColor = theme.colorScheme.outline;
      case AdmissionButtonStyle.destructive:
        backgroundColor = theme.colorScheme.error;
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: backgroundColor != null
          ? ElevatedButton.styleFrom(backgroundColor: backgroundColor)
          : null,
      child: Text(config.label),
    );
  }
}

class _BottomTicketBarSkeleton extends StatelessWidget {
  const _BottomTicketBarSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MinglitSkeleton(width: 40, height: 12),
                SizedBox(height: MinglitSpacing.xsmall),
                MinglitSkeleton(width: 100, height: 24),
              ],
            ),
            const SizedBox(width: MinglitSpacing.large),
            Expanded(
              child: MinglitSkeleton(
                height: 48,
                borderRadius: BorderRadius.circular(MinglitRadius.card),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
