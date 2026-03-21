/// Result of a refund eligibility calculation.
class RefundCalculation {
  /// Creates a [RefundCalculation].
  const RefundCalculation({
    required this.refundPercentage,
    required this.refundAmount,
    required this.feeAmount,
  });

  /// Percentage of the payment that is refundable (0 or 100).
  final int refundPercentage;

  /// Amount to be refunded in the smallest currency unit.
  final int refundAmount;

  /// Non-refundable fee amount.
  final int feeAmount;
}

/// Calculates refund eligibility based on event start time and payment date.
class RefundCalculator {
  /// Calculates refund eligibility.
  static RefundCalculation calculate({
    required DateTime eventStartTime,
    required int paymentAmount,
    required DateTime? paidAt,
    required int gracePeriodHours,
    required int cutoffDays,
    DateTime? now,
  }) {
    final baseTime = now ?? DateTime.now();

    // Fix #133: 미래 paidAt는 음수 duration으로 grace period를 통과하므로 명시적으로 제외
    final withinGracePeriod =
        paidAt != null &&
        !paidAt.isAfter(baseTime) &&
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
