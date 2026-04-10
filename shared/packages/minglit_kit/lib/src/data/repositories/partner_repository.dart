import 'package:image_picker/image_picker.dart' show XFile;
import 'package:minglit_kit/src/data/models/partner.dart';
import 'package:minglit_kit/src/data/models/partner_application.dart';
import 'package:minglit_kit/src/utils/exceptions.dart';
import 'package:minglit_kit/src/utils/image_utils.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'partner_application_repository.dart';
part 'partner_member_repository.dart';
part 'partner_repository.g.dart';

/// Provider for PartnerRepository.
@Riverpod(keepAlive: true)
PartnerRepository partnerRepository(Ref ref) {
  return PartnerRepository();
}

/// Repository for managing Partner-related data.
///
/// Handles database interactions for:
/// - Partner queries (list, detail, revenue stats).
/// - Partner Application (Submit, List, Review).
/// - Member Management (List, Update roles).
class PartnerRepository extends _SupabasePartnerContextBase
    with _PartnerMemberRepository, _PartnerApplicationRepository {
  /// Creates a [PartnerRepository] with a [SupabaseClient].
  PartnerRepository({SupabaseClient? supabase})
    : super(supabase ?? Supabase.instance.client);
}

abstract class _SupabasePartnerContext {
  SupabaseClient get supabaseClient;
}

abstract class _SupabasePartnerContextBase implements _SupabasePartnerContext {
  const _SupabasePartnerContextBase(this.supabaseClient);

  @override
  final SupabaseClient supabaseClient;

  /// Fetches all active partners.
  Future<List<Partner>> getPartners() async {
    Log.d('getPartners called');
    try {
      final data =
          await supabaseClient
                  .from('partners')
                  .select()
                  .eq('is_active', true)
                  .order('created_at', ascending: false)
              as List;
      final result = data.map((json) {
        return Partner.fromJson(json as Map<String, dynamic>);
      }).toList();

      Log.d('getPartners success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] getPartners Error', e, st);
      rethrow;
    }
  }

  /// Fetches partners managed by the current user.
  Future<List<Partner>> getMyManagedPartners() async {
    final userId = supabaseClient.auth.currentUser?.id;
    Log.d('getMyManagedPartners called | user: $userId');

    if (userId == null) {
      Log.w('⚠️ [PartnerRepo] User not logged in');
      return [];
    }

    // 1. Get partner_ids from permissions
    try {
      final permissions =
          await supabaseClient
                  .from('partner_member_permissions')
                  .select('partner_id')
                  .eq('user_id', userId)
              as List;

      Log.d('🔍 [PartnerRepo] Found permissions raw data: $permissions');
      final partnerIds = permissions
          .map((e) {
            return (e as Map<String, dynamic>)['partner_id'] as String?;
          })
          .whereType<String>()
          .toList();

      if (partnerIds.isEmpty) {
        Log.w('⚠️ [PartnerRepo] No managed partners found for user');
        return [];
      }

      // 2. Get partners details
      final data =
          await supabaseClient
                  .from('partners')
                  .select()
                  .inFilter('id', partnerIds)
                  .eq('is_active', true)
              as List;
      final result = data.map((json) {
        return Partner.fromJson(json as Map<String, dynamic>);
      }).toList();
      Log.d('getMyManagedPartners success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] getMyManagedPartners Error', e, st);
      rethrow;
    }
  }

  /// Fetches a specific partner by ID.
  Future<Partner?> getPartnerById(String partnerId) async {
    Log.d('getPartnerById called | partnerId: $partnerId');
    try {
      final data = await supabaseClient
          .from('partners')
          .select()
          .eq('id', partnerId)
          .maybeSingle();

      if (data == null) {
        Log.d('getPartnerById success | result: null');
        return null;
      }
      final result = Partner.fromJson(data);
      Log.d('getPartnerById success | name: ${result.name}');
      return result;
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] getPartnerById Error', e, st);
      rethrow;
    }
  }

  /// Fetches the current user's role and permissions for a specific partner.
  Future<Map<String, dynamic>?> getMyMemberRole(String partnerId) async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final data = await supabaseClient
          .from('partner_member_permissions')
          .select('role, permissions')
          .match({'partner_id': partnerId, 'user_id': userId})
          .maybeSingle();

      return data;
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] getMyMemberRole Error', e, st);
      rethrow;
    }
  }

  /// Fetches aggregated revenue stats for a partner.
  Future<Map<String, dynamic>> getPartnerRevenueStats(
    String partnerId,
  ) async {
    Log.d('getPartnerRevenueStats called | partnerId: $partnerId');
    try {
      final data = await supabaseClient
          .from('partner_revenue_stats')
          .select()
          .eq('partner_id', partnerId)
          .maybeSingle();

      if (data == null) {
        return {
          'partner_id': partnerId,
          'total_sales': 0,
          'total_refunds': 0,
          'net_amount': 0,
        };
      }
      return data;
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] getPartnerRevenueStats Error', e, st);
      rethrow;
    }
  }

  /// Fetches monthly revenue stats for charting.
  Future<List<Map<String, dynamic>>> getPartnerMonthlyRevenue(
    String partnerId,
  ) async {
    Log.d('getPartnerMonthlyRevenue called | partnerId: $partnerId');
    try {
      final data =
          await supabaseClient
                  .from('partner_monthly_revenue')
                  .select()
                  .eq('partner_id', partnerId)
                  .order('month', ascending: true)
              as List;
      return data.map((entry) {
        return entry as Map<String, dynamic>;
      }).toList();
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] getPartnerMonthlyRevenue Error', e, st);
      rethrow;
    }
  }

  /// Fetches settlement records for a partner from settlement_items table.
  Future<List<Map<String, dynamic>>> getPartnerSettlements(
    String partnerId,
  ) async {
    Log.d('getPartnerSettlements called | partnerId: $partnerId');
    try {
      final data =
          await supabaseClient
                  .from('settlement_items')
                  .select()
                  .eq('partner_id', partnerId)
                  .order('settlement_period_start', ascending: false)
              as List;
      return data.map((entry) {
        return entry as Map<String, dynamic>;
      }).toList();
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] getPartnerSettlements Error', e, st);
      rethrow;
    }
  }
}
