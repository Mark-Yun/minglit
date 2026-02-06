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

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    AdmissionState state,
  ) {
    final theme = Theme.of(context);
    var text = '참가 신청하기';
    VoidCallback? onPressed;
    Color? backgroundColor;

    switch (state.status) {
      case EventAdmissionStatus.guest:
        text = '로그인하고 신청하기';
        onPressed = () {
          final currentPath = GoRouterState.of(context).uri.toString();
          ref.read(authCoordinatorProvider).goToLogin(from: currentPath);
        };
      case EventAdmissionStatus.identityRequired:
        text = '본인인증 후 신청하기';
        onPressed = () async {
          final success = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const IdentityVerificationScreen(),
              fullscreenDialog: true,
            ),
          );
          if (success ?? false) {
            ref.invalidate(eventAdmissionControllerProvider(event));
          }
        };
      case EventAdmissionStatus.qualificationRequired:
        text = '신청하기';
        onPressed = () async {
          // Open Ticket Sheet, it will show which ticket requires qualification
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => TicketSelectionSheet(event: event),
          );
          // Refresh state as user might have applied
          ref.invalidate(eventAdmissionControllerProvider(event));
        };
      case EventAdmissionStatus.notEligible:
        text = state.ineligibleReason ?? '참여 조건 미달';
        onPressed = null; // Disabled
        backgroundColor = theme.colorScheme.outline;
      case EventAdmissionStatus.eligible:
        text = '참가 신청하기';
        onPressed = () {
          unawaited(
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => TicketSelectionSheet(event: event),
            ),
          );
        };
      case EventAdmissionStatus.pendingPayment:
        text = '결제 계속하기';
        onPressed = () {
          unawaited(
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => TicketSelectionSheet(event: event),
            ),
          );
        };
      case EventAdmissionStatus.applied:
        text = '이미 신청한 이벤트';
        onPressed = () {
          handleMinglitError(
            context,
            const MinglitUserException(
              '이미 신청이 완료된 이벤트입니다.\n마이페이지에서 티켓을 확인해주세요.',
            ),
          );
        };
      case EventAdmissionStatus.rejected:
        text = '심사 반려 (사유 확인)';
        backgroundColor = theme.colorScheme.error;
        onPressed = () async {
          final confirmed = await context.showMinglitConfirm(
            title: '심사 결과 안내',
            message:
                '반려 사유: ${state.rejectionReason ?? "정보 부족"}\n\n'
                '기존 신청을 취소하고 다시 신청하시겠습니까?',
            confirmLabel: '다시 신청하기',
            cancelLabel: '닫기',
          );

          if (confirmed && context.mounted) {
            final user = state.user;
            if (user == null) return;
            final loading = ref.read(globalLoadingControllerProvider.notifier)
              ..show();
            try {
              await ref
                  .read(eventRepositoryProvider)
                  .deleteApplication(
                    eventId: event.id,
                    userId: user.id,
                  );
              // Refresh state
              ref.invalidate(eventAdmissionControllerProvider(event));
              if (context.mounted) {
                unawaited(
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => TicketSelectionSheet(event: event),
                  ),
                );
              }
            } finally {
              loading.hide();
            }
          }
        };
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: backgroundColor != null
          ? ElevatedButton.styleFrom(backgroundColor: backgroundColor)
          : null,
      child: Text(text),
    );
  }
}
