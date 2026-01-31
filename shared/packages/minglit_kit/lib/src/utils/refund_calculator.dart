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
    DateTime? now,
  }) {
    final baseTime = now ?? DateTime.now();
    final diff = eventStartTime.difference(baseTime);

    var percentage = 0;
    if (diff >= const Duration(days: 7)) {
      percentage = 100;
    } else if (diff >= const Duration(days: 3)) {
      percentage = 80;
    } else if (diff >= const Duration(days: 1)) {
      percentage = 50;
    }

    final refundAmount = (paymentAmount * percentage) ~/ 100;
    final feeAmount = paymentAmount - refundAmount;

    return RefundCalculation(
      refundPercentage: percentage,
      refundAmount: refundAmount,
      feeAmount: feeAmount,
    );
  }
}
