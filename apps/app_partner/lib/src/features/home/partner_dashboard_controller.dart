import 'dart:async';

import 'package:app_partner/src/features/party/party_providers.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'partner_dashboard_controller.freezed.dart';
part 'partner_dashboard_controller.g.dart';

@freezed
abstract class PartnerDashboardState with _$PartnerDashboardState {
  const factory PartnerDashboardState({
    @Default(0) int pendingReviewCount,
    @Default([]) List<Event> todayEvents,
    @Default(false) bool hasRevenuePermission,
    @Default(PartnerRevenueSummary()) PartnerRevenueSummary revenueSummary,
    @Default([]) List<PartnerMonthlyRevenue> monthlyRevenue,
    @Default([]) List<PartnerSettlement> settlements,
    @Default(AsyncValue<void>.loading()) AsyncValue<void> status,
  }) = _PartnerDashboardState;
}

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

@riverpod
class PartnerDashboardController extends _$PartnerDashboardController {
  @override
  PartnerDashboardState build() {
    // Schedule loading after build() returns so that `state` is initialized.
    // unawaited() runs synchronously until the first await, which would
    // access `state` before build() has returned — causing
    // "Tried to read the state of an uninitialized provider".
    unawaited(Future.microtask(loadDashboardData));
    return const PartnerDashboardState();
  }

  Future<void> loadDashboardData() async {
    state = state.copyWith(status: const AsyncValue.loading());

    try {
      final partner = await ref.read(currentPartnerInfoProvider.future);
      if (partner == null) {
        state = state.copyWith(
          status: const AsyncValue.data(null),
          pendingReviewCount: 0,
          todayEvents: [],
          hasRevenuePermission: false,
        );
        return;
      }

      final eventRepo = ref.read(eventRepositoryProvider);
      final partnerRepo = ref.read(partnerRepositoryProvider);

      // 1. Pending Count
      final pendingCount = await eventRepo.getPendingApplicationCount(
        partner.id,
      );

      // 2. Today's Events
      final todayEvents = await eventRepo.getTodayEvents(partner.id);

      // 3. Permission Check
      final memberInfo = await partnerRepo.getMyMemberRole(partner.id);
      final role = memberInfo?['role'] as String?;
      final permissions =
          (memberInfo?['permissions'] as List?)?.cast<String>() ?? [];

      final hasPermission =
          role == 'owner' || permissions.contains('SETTLEMENT_VIEW');

      var revenueSummary = const PartnerRevenueSummary();
      var monthlyRevenue = const <PartnerMonthlyRevenue>[];
      var settlements = const <PartnerSettlement>[];

      if (hasPermission) {
        final revenueJson = await partnerRepo.getPartnerRevenueStats(
          partner.id,
        );
        revenueSummary = PartnerRevenueSummary.fromJson(revenueJson);

        final monthlyJson = await partnerRepo.getPartnerMonthlyRevenue(
          partner.id,
        );
        monthlyRevenue = monthlyJson
            .map(PartnerMonthlyRevenue.fromJson)
            .toList(growable: false);

        final settlementJson = await partnerRepo.getPartnerSettlements(
          partner.id,
        );
        settlements = settlementJson
            .map(PartnerSettlement.fromJson)
            .toList(growable: false);
      }

      state = state.copyWith(
        status: const AsyncValue.data(null),
        pendingReviewCount: pendingCount,
        todayEvents: todayEvents,
        hasRevenuePermission: hasPermission,
        revenueSummary: revenueSummary,
        monthlyRevenue: monthlyRevenue,
        settlements: settlements,
      );
    } on Exception catch (e, st) {
      state = state.copyWith(status: AsyncValue.error(e, st));
    }
  }
}
