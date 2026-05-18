/// Partner + settlement domain ProviderScope overrides for demo flavor.
///
/// All Supabase calls are intercepted by fake implementations that return
/// fixture data from `lib/fixtures/`. The [PoisonSupabaseClient] is passed
/// to every `super(...)` so any un-overridden method crashes loudly rather
/// than silently returning empty data.
library;

// ignore: implementation_imports
import 'package:riverpod/src/internals.dart' show Override;
import 'package:minglit_kit/minglit_kit.dart';
import 'package:minglit_kit/src/data/repositories/staff_repository.dart';

import '../fixtures/demo_partners.dart';
import '../fixtures/demo_settlements.dart';
import '../fixtures/demo_world.dart';
import 'poison_supabase_client.dart';

// ── Partner Repository ────────────────────────────────────────────────────────

class _DemoPartnerRepository extends PartnerRepository {
  _DemoPartnerRepository() : super(supabase: const PoisonSupabaseClient());

  @override
  Future<List<Partner>> getPartners() async => demoPartners;

  @override
  Future<List<Partner>> getMyManagedPartners() async => [demoPartnerSelf];

  @override
  Future<Partner?> getPartnerById(String partnerId) async {
    try {
      return demoPartners.firstWhere((p) => p.id == partnerId);
    } on StateError {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getMyMemberRole(String partnerId) async {
    if (partnerId == DemoWorld.selfPartnerId) {
      return {'role': 'owner', 'permissions': ['ALL']};
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>> getPartnerRevenueStats(
    String partnerId,
  ) async {
    if (partnerId != DemoWorld.selfPartnerId) {
      return {
        'partner_id': partnerId,
        'total_sales': 0,
        'total_refunds': 0,
        'net_amount': 0,
      };
    }
    // Aggregate from completed settlement items
    final completed = demoSettlementItems
        .where((s) => s.status == 'COMPLETED')
        .toList();
    final totalGross =
        completed.fold<int>(0, (sum, s) => sum + s.grossAmount);
    final totalNet =
        completed.fold<int>(0, (sum, s) => sum + s.netAmount);
    return {
      'partner_id': partnerId,
      'total_sales': totalGross,
      'total_refunds': 0,
      'net_amount': totalNet,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getPartnerMonthlyRevenue(
    String partnerId,
  ) async {
    if (partnerId != DemoWorld.selfPartnerId) return [];
    // Return last 6 months aggregated from settlement items
    return demoSettlementItems.map((s) {
      return {
        'partner_id': partnerId,
        'month': s.settlementPeriodStart?.toIso8601String() ?? '',
        'gross_amount': s.grossAmount,
        'net_amount': s.netAmount,
      };
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getPartnerSettlements(
    String partnerId,
  ) async {
    if (partnerId != DemoWorld.selfPartnerId) return [];
    return demoSettlementItems.map((s) => s.toJson()).toList();
  }

  // ── Member management (mixin forwarded) ──────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getPartnerMembers(
    String partnerId,
  ) async {
    if (partnerId != DemoWorld.selfPartnerId) return [];
    return List<Map<String, dynamic>>.from(demoPartnerMembers);
  }

  @override
  Future<void> updateMemberRole({
    required String partnerId,
    required String userId,
    required String role,
  }) async {
    // Demo: accept silently — no state mutation needed for captures.
  }

  @override
  Future<void> updateMemberPermissions({
    required String partnerId,
    required String userId,
    required List<String> permissions,
  }) async {
    // Demo: accept silently.
  }

  // ── Application management (mixin forwarded) ─────────────────────────────

  @override
  Future<PartnerApplication?> getMyApplication() async =>
      demoPartnerApplications.first;

  @override
  Future<List<PartnerApplication>> getAllApplications({
    String? status,
    String? searchTerm,
  }) async {
    var apps = demoPartnerApplications;
    if (status != null && status != 'all') {
      apps = apps.where((a) => a.status == status).toList();
    }
    if (searchTerm != null && searchTerm.isNotEmpty) {
      final q = searchTerm.toLowerCase();
      apps = apps
          .where(
            (a) =>
                (a.brandName ?? '').toLowerCase().contains(q) ||
                (a.bizName ?? '').toLowerCase().contains(q),
          )
          .toList();
    }
    return apps;
  }

  @override
  Future<void> reviewApplication({
    required String applicationId,
    required String status,
    String? adminComment,
  }) async {
    // Demo: accept silently.
  }

  @override
  Future<String> getSignedUrl(String path) async =>
      'https://placehold.co/800x600/cccccc/000000?text=Demo+Doc';
}

// ── Settlement Repository ─────────────────────────────────────────────────────

class _DemoSettlementRepository extends SettlementRepository {
  _DemoSettlementRepository() : super(supabase: const PoisonSupabaseClient());

  @override
  Future<List<SettlementItemDetail>> getSettlementItems({
    required String partnerId,
    String? status,
    DateTime? dateStart,
    DateTime? dateEnd,
    int limit = 20,
    int offset = 0,
  }) async {
    if (partnerId != DemoWorld.selfPartnerId) return [];
    var items = demoSettlementItems;
    if (status != null) {
      items = items.where((s) => s.status == status).toList();
    }
    if (dateStart != null) {
      items =
          items.where((s) => !s.createdAt.isBefore(dateStart)).toList();
    }
    if (dateEnd != null) {
      items =
          items.where((s) => !s.createdAt.isAfter(dateEnd)).toList();
    }
    final end = (offset + limit).clamp(0, items.length);
    return offset >= items.length ? [] : items.sublist(offset, end);
  }

  @override
  Future<SettlementItemDetail?> getSettlementItemDetail(
    String itemId,
  ) async {
    try {
      return demoSettlementItems.firstWhere((s) => s.id == itemId);
    } on StateError {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> getSettlementDashboard({
    required String partnerId,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    if (partnerId != DemoWorld.selfPartnerId) {
      return {
        'status_counts': <String, int>{},
        'completed_net_total': 0,
        'completed_gross_total': 0,
        'total_items': 0,
      };
    }
    final statusCounts = <String, int>{};
    var completedNet = 0;
    var completedGross = 0;
    for (final s in demoSettlementItems) {
      statusCounts[s.status] = (statusCounts[s.status] ?? 0) + 1;
      if (s.status == 'COMPLETED') {
        completedNet += s.netAmount;
        completedGross += s.grossAmount;
      }
    }
    return {
      'status_counts': statusCounts,
      'completed_net_total': completedNet,
      'completed_gross_total': completedGross,
      'total_items': demoSettlementItems.length,
    };
  }

  @override
  Future<Map<String, dynamic>?> getEventInfo(String eventId) async {
    // Minimal stub — full event fixture is in demo_events.dart (P1-2).
    return {'id': eventId, 'title': '데모 이벤트', 'start_time': null};
  }

  @override
  Future<Map<String, dynamic>?> getBankAccount(String partnerId) async {
    if (partnerId != DemoWorld.selfPartnerId) return null;
    return {
      'bank_name': demoBankAccount['bank_name'],
      'account_holder': demoBankAccount['account_holder'],
      'account_number': demoBankAccount['account_number'],
    };
  }

  @override
  Future<void> upsertBankAccount({
    required String partnerId,
    required String bankName,
    required String accountHolder,
    required String accountNumber,
  }) async {
    // Demo: accept silently.
  }

  @override
  Future<Map<String, dynamic>?> getPartnerSettlementInfo(
    String partnerId,
  ) async {
    if (partnerId != DemoWorld.selfPartnerId) return null;
    return Map<String, dynamic>.from(demoBankAccount);
  }

  @override
  Future<Map<String, dynamic>> retryPayout({
    required String payoutId,
    required String partnerId,
  }) async =>
      {'status': 'queued', 'payout_id': payoutId};
}

// ── Staff Repository ──────────────────────────────────────────────────────────

class _DemoStaffRepository extends StaffRepository {
  _DemoStaffRepository()
    : super(supabase: const PoisonSupabaseClient(), redirectUrl: null);

  @override
  Future<void> saveStaffToken(String token) async {}

  @override
  Future<void> clearStaffToken() async {}

  @override
  Future<User?> verifyStaffStatus() async => null;

  @override
  Future<void> sendMagicLink(String email) async {}
}

// ── Check-in Repository ───────────────────────────────────────────────────────

class _DemoCheckinRepository extends CheckinRepository {
  _DemoCheckinRepository()
    : super(
        crypto: TicketCrypto(),
        supabase: const PoisonSupabaseClient(),
      );

  @override
  Future<bool> verifyAndCheckin({
    required dynamic token,
    required dynamic serverPublicKey,
  }) async => true; // Demo: always succeed
}

// ── Overrides list ────────────────────────────────────────────────────────────

List<Override> partnerDomainOverrides() => [
  partnerRepositoryProvider.overrideWith((_) => _DemoPartnerRepository()),
  settlementRepositoryProvider.overrideWith(
    (_) => _DemoSettlementRepository(),
  ),
  staffRepositoryProvider.overrideWith((_) => _DemoStaffRepository()),
  checkinRepositoryProvider.overrideWith((_) => _DemoCheckinRepository()),
];
