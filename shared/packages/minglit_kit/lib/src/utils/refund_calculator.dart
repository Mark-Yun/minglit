class RefundCalculation {
  const RefundCalculation({
    required this.refundPercentage,
    required this.refundAmount,
    required this.feeAmount,
  });

  final int refundPercentage;
  final int refundAmount;
  final int feeAmount;
}

class RefundCalculator {
  static RefundCalculation calculate({
    required DateTime eventStartTime,
    required int paymentAmount,
    required DateTime? paidAt,
    required int gracePeriodHours,
    required int cutoffDays,
    DateTime? now,
  }) {
    final baseTime = now ?? DateTime.now();

    final withinGracePeriod =
        paidAt != null &&
        baseTime.difference(paidAt) <= Duration(hours: gracePeriodHours);

    final withinCutoff =
        eventStartTime.difference(baseTime) >= Duration(days: cutoffDays);

    final isRefundable = withinGracePeriod || withinCutoff;
    final percentage = isRefundable ? 100 : 0;
    final refundAmount = isRefundable ? paymentAmount : 0;
    final feeAmount = paymentAmount - refundAmount;

    return RefundCalculation(
      refundPercentage: percentage,
      refundAmount: refundAmount,
      feeAmount: feeAmount,
    );
  }
}
