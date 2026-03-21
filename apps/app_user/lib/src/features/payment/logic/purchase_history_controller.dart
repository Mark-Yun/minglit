import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'purchase_history_controller.g.dart';

/// **Purchase History Controller**
///
/// Manages the state of the user's purchase history.
/// Fetches data from EventRepository.
@riverpod
class PurchaseHistoryController extends _$PurchaseHistoryController {
  @override
  FutureOr<List<EventApplication>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      // Return empty list or throw error depending on UX.
      return [];
    }

    final repository = ref.watch(eventRepositoryProvider);
    return repository.getMyPurchaseHistory(user.id);
  }

  bool isActiveTicket(EventApplication application) {
    return application.status == 'paid' || application.status == 'approved';
  }

  bool isRefundReady(EventApplication application) {
    final eventStartTime = application.event?.startTime;
    return application.paymentId != null &&
        application.paymentAmount != null &&
        eventStartTime != null;
  }

  bool canCancel(EventApplication application) {
    return isActiveTicket(application) &&
        isRefundReady(application) &&
        application.refundStatus == 'none';
  }

  RefundCalculation calculateRefund({
    required DateTime eventStartTime,
    required int paymentAmount,
    required DateTime? paidAt,
    required int gracePeriodHours,
    required int cutoffDays,
    DateTime? now,
  }) {
    return RefundCalculator.calculate(
      eventStartTime: eventStartTime,
      paymentAmount: paymentAmount,
      paidAt: paidAt,
      gracePeriodHours: gracePeriodHours,
      cutoffDays: cutoffDays,
      now: now,
    );
  }

  Future<void> runRefundFlow({
    required String? paymentId,
    required int? paymentAmount,
    required DateTime? eventStartTime,
    required DateTime? paidAt,
    required Future<void> Function() showMissingInfo,
    required Future<void> Function() showNotEligible,
    required Future<bool> Function(RefundCalculation calculation) confirmRefund,
    required Future<bool> Function(String message) showError,
    required Future<void> Function() onSuccess,
  }) async {
    if (paymentId == null || paymentAmount == null || eventStartTime == null) {
      await showMissingInfo();
      return;
    }

    // Fix #133: 정책 조회 실패 시 기본값(2/7)으로 환불 플로우가 계속 진행되도록 보호
    var gracePeriodHours = 2;
    var cutoffDays = 7;
    try {
      final policyRepo = ref.read(policyRepositoryProvider);
      final policy = await policyRepo.getRefundPolicy();
      gracePeriodHours = (policy?['grace_period_hours'] as num?)?.toInt() ?? 2;
      cutoffDays = (policy?['cutoff_days'] as num?)?.toInt() ?? 7;
    } on Object {
      // 정책 조회 실패 시 기본 정책으로 진행
    }

    final calculation = calculateRefund(
      eventStartTime: eventStartTime,
      paymentAmount: paymentAmount,
      paidAt: paidAt,
      gracePeriodHours: gracePeriodHours,
      cutoffDays: cutoffDays,
    );

    if (calculation.refundPercentage == 0) {
      await showNotEligible();
      return;
    }

    final confirmed = await confirmRefund(calculation);
    if (!confirmed) return;

    await _requestRefund(
      paymentId: paymentId,
      calculation: calculation,
      showError: showError,
      onSuccess: onSuccess,
    );
  }

  Future<void> _requestRefund({
    required String paymentId,
    required RefundCalculation calculation,
    required Future<bool> Function(String message) showError,
    required Future<void> Function() onSuccess,
  }) async {
    final loading = ref.read(globalLoadingControllerProvider.notifier)..show();
    try {
      await ref.read(eventRepositoryProvider).cancelPayment(
            paymentId: paymentId,
            refundAmount: calculation.refundAmount,
            reason: '사용자 예매 취소',
          );

      ref.invalidate(purchaseHistoryControllerProvider);
      await onSuccess();
    } on Object catch (e, st) {
      final exception = MinglitException.from(e, st);
      final message = exception is MinglitSystemException
          ? exception.userMessage
          : exception.message;
      final retry = await showError(message);
      if (retry) {
        await _requestRefund(
          paymentId: paymentId,
          calculation: calculation,
          showError: showError,
          onSuccess: onSuccess,
        );
      }
    } finally {
      loading.hide();
    }
  }

  // Future features: infinite scroll, filtering, etc.
}
