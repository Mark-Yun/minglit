// Data models for partner revenue and settlement information.
//
// These models are used by both the settlement feature and the
// partner dashboard.

class PartnerRevenueSummary {
  const PartnerRevenueSummary({
    this.totalSales = 0,
    this.totalRefunds = 0,
    this.netAmount = 0,
  });

  factory PartnerRevenueSummary.fromJson(Map<String, dynamic> json) {
    return PartnerRevenueSummary(
      totalSales: _toInt(json['total_sales']),
      totalRefunds: _toInt(json['total_refunds']),
      netAmount: _toInt(json['net_amount']),
    );
  }

  final int totalSales;
  final int totalRefunds;
  final int netAmount;
}

class PartnerMonthlyRevenue {
  const PartnerMonthlyRevenue({
    required this.month,
    this.totalSales = 0,
    this.totalRefunds = 0,
    this.netAmount = 0,
  });

  factory PartnerMonthlyRevenue.fromJson(Map<String, dynamic> json) {
    return PartnerMonthlyRevenue(
      month: _toDateTime(json['month']),
      totalSales: _toInt(json['total_sales']),
      totalRefunds: _toInt(json['total_refunds']),
      netAmount: _toInt(json['net_amount']),
    );
  }

  final DateTime month;
  final int totalSales;
  final int totalRefunds;
  final int netAmount;
}

class PartnerSettlement {
  const PartnerSettlement({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
    required this.totalSales,
    required this.totalRefunds,
    required this.pgFee,
    required this.platformFee,
    required this.vat,
    required this.netAmount,
    required this.status,
  });

  factory PartnerSettlement.fromJson(Map<String, dynamic> json) {
    return PartnerSettlement(
      id: json['id'] as String? ?? '',
      eventId: json['event_id'] as String? ?? '',
      eventTitle: json['event_title'] as String? ?? '',
      eventDate: _toDateTime(json['event_date']),
      totalSales: _toInt(json['total_sales']),
      totalRefunds: _toInt(json['total_refunds']),
      pgFee: _toInt(json['pg_fee']),
      platformFee: _toInt(json['platform_fee']),
      vat: _toInt(json['vat']),
      netAmount: _toInt(json['net_amount']),
      // Normalize UPPERCASE statuses to lowercase for backward compatibility
      status: (json['status'] as String? ?? 'pending').toLowerCase(),
    );
  }

  final String id;
  final String eventId;
  final String eventTitle;
  final DateTime eventDate;
  final int totalSales;
  final int totalRefunds;
  final int pgFee;
  final int platformFee;
  final int vat;
  final int netAmount;
  final String status;
}

/// Represents a single settlement item from the `settlement_items` table.
/// Uses UPPERCASE status values natively (see [SettlementItemStatus]).
class SettlementItem {
  const SettlementItem({
    required this.id,
    required this.partnerId,
    required this.settlementPeriodStart,
    required this.settlementPeriodEnd,
    required this.currency,
    required this.sourceType,
    required this.sourceId,
    required this.status,
    required this.grossAmount,
    required this.platformFeeRate,
    required this.platformFeeAmount,
    required this.pgFeeRate,
    required this.pgFeeAmount,
    required this.vatRate,
    required this.vatAmount,
    required this.netAmount,
    required this.retryable,
    required this.retryCount,
    required this.calcChecksum,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.holdReasonCode,
    this.holdReasonDetail,
    this.failureReasonCode,
    this.failureMessage,
    this.nextRetryAt,
    this.payoutId,
    this.eventCompletedAt,
  });

  factory SettlementItem.fromJson(Map<String, dynamic> json) {
    return SettlementItem(
      id: json['id'] as String? ?? '',
      partnerId: json['partner_id'] as String? ?? '',
      settlementPeriodStart: _toDate(json['settlement_period_start']),
      settlementPeriodEnd: _toDate(json['settlement_period_end']),
      currency: json['currency'] as String? ?? 'KRW',
      sourceType: json['source_type'] as String? ?? '',
      sourceId: json['source_id'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      grossAmount: _toInt(json['gross_amount']),
      platformFeeRate: _toDouble(json['platform_fee_rate']),
      platformFeeAmount: _toInt(json['platform_fee_amount']),
      pgFeeRate: _toDouble(json['pg_fee_rate']),
      pgFeeAmount: _toInt(json['pg_fee_amount']),
      vatRate: _toDouble(json['vat_rate']),
      vatAmount: _toInt(json['vat_amount']),
      netAmount: _toInt(json['net_amount']),
      holdReasonCode: json['hold_reason_code'] as String?,
      holdReasonDetail: json['hold_reason_detail'] as String?,
      failureReasonCode: json['failure_reason_code'] as String?,
      failureMessage: json['failure_message'] as String?,
      retryable: json['retryable'] as bool? ?? false,
      retryCount: _toInt(json['retry_count']),
      nextRetryAt: json['next_retry_at'] != null
          ? _toDateTime(json['next_retry_at'])
          : null,
      payoutId: json['payout_id'] as String?,
      calcChecksum: json['calc_checksum'] as String? ?? '',
      version: _toInt(json['version']),
      eventCompletedAt: json['event_completed_at'] != null
          ? _toDateTime(json['event_completed_at'])
          : null,
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
    );
  }

  final String id;
  final String partnerId;
  final DateTime settlementPeriodStart;
  final DateTime settlementPeriodEnd;
  final String currency;
  final String sourceType;
  final String sourceId;
  // 'PENDING','HOLD','CANCELED','READY','PROCESSING','COMPLETED','FAILED'
  final String status;
  final int grossAmount;
  final double platformFeeRate;
  final int platformFeeAmount;
  final double pgFeeRate;
  final int pgFeeAmount;
  final double vatRate;
  final int vatAmount;
  final int netAmount;
  final String? holdReasonCode;
  final String? holdReasonDetail;
  final String? failureReasonCode;
  final String? failureMessage;
  final bool retryable;
  final int retryCount;
  final DateTime? nextRetryAt;
  final String? payoutId;
  final String calcChecksum;
  final int version;
  final DateTime? eventCompletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

DateTime _toDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

DateTime _toDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}

/// Status constants for [SettlementItem].
abstract class SettlementItemStatus {
  static const pending = 'PENDING';
  static const hold = 'HOLD';
  static const canceled = 'CANCELED';
  static const ready = 'READY';
  static const processing = 'PROCESSING';
  static const completed = 'COMPLETED';
  static const failed = 'FAILED';
}
