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
      status: json['status'] as String? ?? 'pending',
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

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

DateTime _toDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}
