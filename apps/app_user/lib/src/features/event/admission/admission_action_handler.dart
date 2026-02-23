part of 'event_admission_controller.dart';

/// Extension methods for EventAdmissionController button configuration.
///
/// Extracted from the controller to keep file sizes manageable.
/// Pure mapping from state to button config — no ref/state access needed.
extension AdmissionActions on EventAdmissionController {
  AdmissionButtonConfig buttonConfig(AdmissionState state) {
    switch (state.status) {
      case EventAdmissionStatus.guest:
        return const AdmissionButtonConfig(label: '로그인하고 신청하기');
      case EventAdmissionStatus.identityRequired:
        return const AdmissionButtonConfig(label: '본인인증 후 신청하기');
      case EventAdmissionStatus.qualificationRequired:
        return const AdmissionButtonConfig(label: '신청하기');
      case EventAdmissionStatus.notEligible:
        return AdmissionButtonConfig(
          label: state.ineligibleReason ?? '참여 조건 미달',
          enabled: false,
          style: AdmissionButtonStyle.disabled,
        );
      case EventAdmissionStatus.eligible:
        return const AdmissionButtonConfig(label: '참가 신청하기');
      case EventAdmissionStatus.pendingPayment:
        return const AdmissionButtonConfig(label: '결제 계속하기');
      case EventAdmissionStatus.applied:
        return const AdmissionButtonConfig(label: '이미 신청한 이벤트');
      case EventAdmissionStatus.rejected:
        return const AdmissionButtonConfig(
          label: '심사 반려 (사유 확인)',
          style: AdmissionButtonStyle.destructive,
        );
    }
  }

  /// Handles user action based on current admission state.
  Future<void> handleAction({
    required BuildContext context,
    required AdmissionState state,
  }) async {
    await _handleAction(this, context: context, state: state);
  }
}

/// Handles user action based on current admission state.
Future<void> _handleAction(
  EventAdmissionController controller, {
  required BuildContext context,
  required AdmissionState state,
}) async {
  switch (state.status) {
    case EventAdmissionStatus.guest:
      final currentPath = GoRouterState.of(context).uri.toString();
      controller.ref.read(authCoordinatorProvider).goToLogin(from: currentPath);
      return;
    case EventAdmissionStatus.identityRequired:
      final success = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const IdentityVerificationScreen(),
          fullscreenDialog: true,
        ),
      );
      if (success ?? false) {
        controller.ref.invalidate(eventAdmissionControllerProvider(controller.event));
      }
      return;
    case EventAdmissionStatus.qualificationRequired:
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => TicketSelectionSheet(event: controller.event),
      );
      controller.ref.invalidate(eventAdmissionControllerProvider(controller.event));
      return;
    case EventAdmissionStatus.notEligible:
      return;
    case EventAdmissionStatus.eligible:
      unawaited(
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => TicketSelectionSheet(event: controller.event),
        ),
      );
      return;
    case EventAdmissionStatus.pendingPayment:
      unawaited(
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => TicketSelectionSheet(event: controller.event),
        ),
      );
      return;
    case EventAdmissionStatus.applied:
      handleMinglitError(
        context,
        const MinglitUserException(
          '이미 신청이 완료된 이벤트입니다.\n마이페이지에서 티켓을 확인해주세요.',
        ),
      );
      return;
    case EventAdmissionStatus.rejected:
      final confirmed = await context.showMinglitConfirm(
        title: '심사 결과 안내',
        message:
            '반래 사유: ${state.rejectionReason ?? "정보 부족"}\n\n'
            '기존 신청을 취소하고 다시 신청하시겠습니까?',
        confirmLabel: '다시 신청하기',
        cancelLabel: '닫기',
      );

      if (confirmed && context.mounted) {
        final user = state.user;
        if (user == null) return;
        final loading = controller.ref.read(globalLoadingControllerProvider.notifier)
          ..show();
        try {
          await controller.ref
              .read(eventRepositoryProvider)
              .deleteApplication(
                eventId: controller.event.id,
                userId: user.id,
              );
          controller.ref.invalidate(eventAdmissionControllerProvider(controller.event));
          if (context.mounted) {
            unawaited(
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => TicketSelectionSheet(event: controller.event),
              ),
            );
          }
        } finally {
          loading.hide();
        }
      }
      return;
  }
}

