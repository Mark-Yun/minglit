/// Settlement item detail models for the partner settlement feature.
///
/// These are plain Dart classes (no Freezed) for simplicity.
library;

/// Summary of a payout associated with a settlement item.
class PayoutSummary {
  /// Creates a [PayoutSummary].
  const PayoutSummary({
    required this.id,
    required this.status,
    required this.totalNetAmount,
    this.scheduledAt,
    this.bankAccountSnapshot,
  });

  /// Creates a [PayoutSummary] from a JSON map.
  factory PayoutSummary.fromJson(Map<String, dynamic> json) {
    return PayoutSummary(
      id: json['id'] as String,
      status: json['status'] as String,
      totalNetAmount: json['total_net_amount'] as int,
      scheduledAt: json['scheduled_at'] == null
          ? null
          : DateTime.parse(json['scheduled_at'] as String),
      bankAccountSnapshot:
          json['bank_account_snapshot'] as Map<String, dynamic>?,
    );
  }

  /// Payout ID.
  final String id;

  /// Payout status: CREATED / READY / PROCESSING / COMPLETED / FAILED / CANCELED.
  final String status;

  /// Scheduled payout date.
  final DateTime? scheduledAt;

  /// Total net amount for this payout batch.
  final int totalNetAmount;

  /// Snapshot of the bank account used for this payout.
  final Map<String, dynamic>? bankAccountSnapshot;

  /// Converts to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'total_net_amount': totalNetAmount,
        'scheduled_at': scheduledAt?.toIso8601String(),
        'bank_account_snapshot': bankAccountSnapshot,
      };
}

/// A single entry in the settlement history log.
class SettlementHistoryEntry {
  /// Creates a [SettlementHistoryEntry].
  const SettlementHistoryEntry({
    required this.eventType,
    required this.fromStatus,
    required this.toStatus,
    required this.createdAt,
    this.details,
  });

  /// Creates a [SettlementHistoryEntry] from a JSON map.
  factory SettlementHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SettlementHistoryEntry(
      eventType: json['event_type'] as String,
      fromStatus: json['from_status'] as String,
      toStatus: json['to_status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  /// Type of the history event (e.g., STATUS_CHANGED).
  final String eventType;

  /// Status before the transition.
  final String fromStatus;

  /// Status after the transition.
  final String toStatus;

  /// When this history entry was created.
  final DateTime createdAt;

  /// Optional additional details about the event.
  final Map<String, dynamic>? details;

  /// Converts to a JSON map.
  Map<String, dynamic> toJson() => {
        'event_type': eventType,
        'from_status': fromStatus,
        'to_status': toStatus,
        'created_at': createdAt.toIso8601String(),
        'details': details,
      };
}

/// An adjustment item linked to a settlement item.
class AdjustmentItemModel {
  /// Creates an [AdjustmentItemModel].
  const AdjustmentItemModel({
    required this.id,
    required this.adjustmentType,
    required this.amountSigned,
    required this.status,
    this.reasonCode,
  });

  /// Creates an [AdjustmentItemModel] from a JSON map.
  factory AdjustmentItemModel.fromJson(Map<String, dynamic> json) {
    return AdjustmentItemModel(
      id: json['id'] as String,
      adjustmentType: json['adjustment_type'] as String,
      amountSigned: json['amount_signed'] as int,
      status: json['status'] as String,
      reasonCode: json['reason_code'] as String?,
    );
  }

  /// Adjustment item ID.
  final String id;

  /// Type of adjustment (e.g., REFUND, PENALTY, BONUS).
  final String adjustmentType;

  /// Signed amount (positive = credit, negative = debit).
  final int amountSigned;

  /// Optional reason code for the adjustment.
  final String? reasonCode;

  /// Adjustment status.
  final String status;

  /// Converts to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'adjustment_type': adjustmentType,
        'amount_signed': amountSigned,
        'reason_code': reasonCode,
        'status': status,
      };
}

/// Full detail of a settlement item, including nested payout, history, and
/// adjustment data.
class SettlementItemDetail {
  /// Creates a [SettlementItemDetail].
  const SettlementItemDetail({
    required this.id,
    required this.partnerId,
    required this.status,
    required this.grossAmount,
    required this.platformFeeAmount,
    required this.pgFeeAmount,
    required this.vatAmount,
    required this.netAmount,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
    required this.retryable,
    required this.retryCount,
    required this.histories,
    required this.adjustments,
    this.eventId,
    this.holdReasonCode,
    this.holdReasonDetail,
    this.failureReasonCode,
    this.failureMessage,
    this.settlementPeriodStart,
    this.settlementPeriodEnd,
    this.processingStartedAt,
    this.processingEndedAt,
    this.payoutId,
    this.payoutInfo,
  });

  /// Creates a [SettlementItemDetail] from a JSON map.
  ///
  /// [payoutData], [historiesData], and [adjustmentsData] are optional
  /// nested data that can be provided separately.
  factory SettlementItemDetail.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? payoutData,
    List<Map<String, dynamic>>? historiesData,
    List<Map<String, dynamic>>? adjustmentsData,
  }) {
    return SettlementItemDetail(
      id: json['id'] as String,
      partnerId: json['partner_id'] as String,
      eventId: json['event_id'] as String?,
      status: json['status'] as String,
      grossAmount: json['gross_amount'] as int,
      platformFeeAmount: json['platform_fee_amount'] as int,
      pgFeeAmount: json['pg_fee_amount'] as int,
      vatAmount: json['vat_amount'] as int,
      netAmount: json['net_amount'] as int,
      currency: json['currency'] as String,
      holdReasonCode: json['hold_reason_code'] as String?,
      holdReasonDetail: json['hold_reason_detail'] as String?,
      failureReasonCode: json['failure_reason_code'] as String?,
      failureMessage: json['failure_message'] as String?,
      settlementPeriodStart: json['settlement_period_start'] == null
          ? null
          : DateTime.parse(json['settlement_period_start'] as String),
      settlementPeriodEnd: json['settlement_period_end'] == null
          ? null
          : DateTime.parse(json['settlement_period_end'] as String),
      processingStartedAt: json['processing_started_at'] == null
          ? null
          : DateTime.parse(json['processing_started_at'] as String),
      processingEndedAt: json['processing_ended_at'] == null
          ? null
          : DateTime.parse(json['processing_ended_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      payoutId: json['payout_id'] as String?,
      retryable: json['retryable'] as bool? ?? false,
      retryCount: json['retry_count'] as int? ?? 0,
      payoutInfo:
          payoutData != null ? PayoutSummary.fromJson(payoutData) : null,
      histories:
          (historiesData ?? []).map(SettlementHistoryEntry.fromJson).toList(),
      adjustments:
          (adjustmentsData ?? []).map(AdjustmentItemModel.fromJson).toList(),
    );
  }

  /// Settlement item ID.
  final String id;

  /// Partner ID who owns this settlement item.
  final String partnerId;

  /// Optional event ID linked to this settlement item.
  final String? eventId;

  /// Settlement status (7-stage: PENDING / HOLD / PROCESSING / COMPLETED /
  /// FAILED / CANCELED / ADJUSTING).
  final String status;

  /// Gross revenue amount before fees.
  final int grossAmount;

  /// Platform fee deducted.
  final int platformFeeAmount;

  /// PG (payment gateway) fee deducted.
  final int pgFeeAmount;

  /// VAT amount.
  final int vatAmount;

  /// Net amount after all deductions.
  final int netAmount;

  /// Currency code (e.g., 'KRW').
  final String currency;

  /// Reason code when the item is on hold.
  final String? holdReasonCode;

  /// Human-readable hold reason detail.
  final String? holdReasonDetail;

  /// Reason code when the item has failed.
  final String? failureReasonCode;

  /// Human-readable failure message.
  final String? failureMessage;

  /// Start of the settlement period.
  final DateTime? settlementPeriodStart;

  /// End of the settlement period.
  final DateTime? settlementPeriodEnd;

  /// When processing started.
  final DateTime? processingStartedAt;

  /// When processing ended.
  final DateTime? processingEndedAt;

  /// When this record was created.
  final DateTime createdAt;

  /// When this record was last updated.
  final DateTime updatedAt;

  /// ID of the associated payout batch.
  final String? payoutId;

  /// Whether this item can be retried after failure.
  final bool retryable;

  /// Number of retry attempts.
  final int retryCount;

  /// Nested payout summary (populated in detail view).
  final PayoutSummary? payoutInfo;

  /// History log entries for this settlement item.
  final List<SettlementHistoryEntry> histories;

  /// Adjustment items linked to this settlement item.
  final List<AdjustmentItemModel> adjustments;

  /// Converts to a JSON map (flat, without nested data).
  Map<String, dynamic> toJson() => {
        'id': id,
        'partner_id': partnerId,
        'event_id': eventId,
        'status': status,
        'gross_amount': grossAmount,
        'platform_fee_amount': platformFeeAmount,
        'pg_fee_amount': pgFeeAmount,
        'vat_amount': vatAmount,
        'net_amount': netAmount,
        'currency': currency,
        'hold_reason_code': holdReasonCode,
        'hold_reason_detail': holdReasonDetail,
        'failure_reason_code': failureReasonCode,
        'failure_message': failureMessage,
        'settlement_period_start': settlementPeriodStart?.toIso8601String(),
        'settlement_period_end': settlementPeriodEnd?.toIso8601String(),
        'processing_started_at': processingStartedAt?.toIso8601String(),
        'processing_ended_at': processingEndedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'payout_id': payoutId,
        'retryable': retryable,
        'retry_count': retryCount,
      };
}
