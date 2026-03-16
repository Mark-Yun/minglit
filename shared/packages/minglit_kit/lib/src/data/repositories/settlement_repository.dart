import 'package:minglit_kit/src/data/models/settlement_item_detail.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'settlement_repository.g.dart';

/// Provider for [SettlementRepository].
@Riverpod(keepAlive: true)
SettlementRepository settlementRepository(Ref ref) {
  return SettlementRepository();
}

/// Repository for managing settlement-related data.
///
/// Handles database interactions for:
/// - Settlement item list and detail queries.
/// - Dashboard aggregation (status counts + amounts).
/// - Event info lookup for display purposes.
class SettlementRepository {
  /// Creates a [SettlementRepository] with an optional [SupabaseClient].
  SettlementRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Fetches a paginated list of settlement items for a partner.
  ///
  /// Optionally filters by [status] and a date range ([dateStart], [dateEnd])
  /// based on created_at.
  Future<List<SettlementItemDetail>> getSettlementItems({
    required String partnerId,
    String? status,
    DateTime? dateStart,
    DateTime? dateEnd,
    int limit = 20,
    int offset = 0,
  }) async {
    Log.d('getSettlementItems called | partnerId: $partnerId');
    try {
      var query = _supabase
          .from('settlement_items')
          .select()
          .eq('partner_id', partnerId);

      if (status != null) {
        query = query.eq('status', status);
      }

      if (dateStart != null) {
        query = query.gte('created_at', dateStart.toIso8601String());
      }

      if (dateEnd != null) {
        query = query.lte('created_at', dateEnd.toIso8601String());
      }

      final data =
          await query.order('created_at').range(offset, offset + limit - 1)
              as List;

      final result = data.map((json) {
        return SettlementItemDetail.fromJson(json as Map<String, dynamic>);
      }).toList();

      Log.d('getSettlementItems success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [SettlementRepo] getSettlementItems Error', e, st);
      rethrow;
    }
  }

  /// Fetches a single settlement item with full nested data.
  ///
  /// Includes payout info, history entries, and adjustment items.
  /// Returns null if the item is not found.
  Future<SettlementItemDetail?> getSettlementItemDetail(String itemId) async {
    Log.d('getSettlementItemDetail called | itemId: $itemId');
    try {
      // 1. Fetch the settlement item.
      final itemData = await _supabase
          .from('settlement_items')
          .select()
          .eq('id', itemId)
          .maybeSingle();

      if (itemData == null) {
        Log.d('getSettlementItemDetail | not found: $itemId');
        return null;
      }

      // 2. Fetch payout info if payout_id exists.
      Map<String, dynamic>? payoutData;
      final payoutId = itemData['payout_id'] as String?;
      if (payoutId != null) {
        payoutData = await _supabase
            .from('payouts')
            .select(
              'id, status, scheduled_at, '
              'total_net_amount, bank_account_snapshot',
            )
            .eq('id', payoutId)
            .maybeSingle();
      }

      // 3. Fetch settlement history entries ordered newest first.
      final historiesRaw =
          await _supabase
                  .from('settlement_histories')
                  .select(
                    'event_type, from_status, to_status, details, created_at',
                  )
                  .eq('settlement_item_id', itemId)
                  .order('created_at', ascending: false)
              as List;

      final historiesData = historiesRaw
          .map((e) => e as Map<String, dynamic>)
          .toList();

      // 4. Fetch adjustment items.
      final adjustmentsRaw =
          await _supabase
                  .from('adjustment_items')
                  .select(
                    'id, adjustment_type, amount_signed, reason_code, status',
                  )
                  .eq('settlement_item_id', itemId)
              as List;

      final adjustmentsData = adjustmentsRaw
          .map((e) => e as Map<String, dynamic>)
          .toList();

      final result = SettlementItemDetail.fromJson(
        itemData,
        payoutData: payoutData,
        historiesData: historiesData,
        adjustmentsData: adjustmentsData,
      );

      Log.d('getSettlementItemDetail success | id: ${result.id}');
      return result;
    } catch (e, st) {
      Log.e('❌ [SettlementRepo] getSettlementItemDetail Error', e, st);
      rethrow;
    }
  }

  /// Returns dashboard aggregation data for a partner.
  ///
  /// Includes count per status and total amounts for COMPLETED items.
  /// Optionally filters by a period ([periodStart], [periodEnd]) based on
  /// created_at.
  Future<Map<String, dynamic>> getSettlementDashboard({
    required String partnerId,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    Log.d('getSettlementDashboard called | partnerId: $partnerId');
    try {
      var query = _supabase
          .from('settlement_items')
          .select('status, net_amount, gross_amount')
          .eq('partner_id', partnerId);

      if (periodStart != null) {
        query = query.gte('created_at', periodStart.toIso8601String());
      }

      if (periodEnd != null) {
        query = query.lte('created_at', periodEnd.toIso8601String());
      }

      final data = await query as List;

      // Aggregate counts per status.
      final statusCounts = <String, int>{};
      var completedNetTotal = 0;
      var completedGrossTotal = 0;

      for (final row in data) {
        final map = row as Map<String, dynamic>;
        final status = map['status'] as String;
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;

        if (status == 'COMPLETED') {
          completedNetTotal += map['net_amount'] as int? ?? 0;
          completedGrossTotal += map['gross_amount'] as int? ?? 0;
        }
      }

      final result = {
        'status_counts': statusCounts,
        'completed_net_total': completedNetTotal,
        'completed_gross_total': completedGrossTotal,
        'total_items': data.length,
      };

      Log.d('getSettlementDashboard success | total: ${data.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [SettlementRepo] getSettlementDashboard Error', e, st);
      rethrow;
    }
  }

  /// Fetches basic event info (title, date, party name) for display.
  ///
  /// Returns null if the event is not found.
  Future<Map<String, dynamic>?> getEventInfo(String eventId) async {
    Log.d('getEventInfo called | eventId: $eventId');
    try {
      final data = await _supabase
          .from('events')
          .select('id, title, date, parties(name)')
          .eq('id', eventId)
          .maybeSingle();

      if (data == null) {
        Log.d('getEventInfo | not found: $eventId');
        return null;
      }

      Log.d('getEventInfo success | title: ${data['title']}');
      return data;
    } catch (e, st) {
      Log.e('❌ [SettlementRepo] getEventInfo Error', e, st);
      rethrow;
    }
  }
}
