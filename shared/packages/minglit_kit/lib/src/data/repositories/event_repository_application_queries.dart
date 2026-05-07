part of 'event_repository.dart';

// Fix #2224: extracted for testability — maps a flat get_event_applications_with_user
// RPC row to an EventApplication-compatible JSON map (nested user + ticket).
// @visibleForTesting via the 'event_application_rpc_mapping_test.dart' test.
Map<String, dynamic> mapEventApplicationRpcRow(Map<String, dynamic> map) {
  return {
    'id': map['application_id'],
    'event_id': map['event_id'],
    'ticket_id': map['ticket_id'],
    'user_id': map['user_id'],
    'payment_id': map['payment_id'],
    'payment_amount': map['payment_amount'],
    'status': map['status'],
    'created_at': map['created_at'],
    'updated_at': map['updated_at'],
    // Fix #2272: surface terminal timestamps for sorting and relative-date trailing
    'paid_at': map['paid_at'],
    'refunded_at': map['refunded_at'],
    'refund_status': map['refund_status'] ?? 'none',
    // Fix #2272: use user_username (nickname from user_profiles).
    // email was previously stored here but leaked to all partner-visible screens.
    // 환불 tab uses _maskIdentifier on username (nickname) for display.
    'user':
        (map['user_name'] != null ||
            map['user_phone'] != null ||
            map['user_email'] != null ||
            map['user_username'] != null)
        ? {
            'id': map['user_id'],
            'name': map['user_name'],
            'username': map['user_username'] ?? '',
            'phone_number': map['user_phone'],
          }
        : null,
    'submission': null,
    // Fix #2224: build nested 'ticket' object from flat RPC columns so
    // that EventApplicationListView can filter by entry group without a
    // separate round-trip.
    'ticket': map['ticket_id'] != null && map['ticket_name'] != null
        ? {
            'id': map['ticket_id'].toString(),
            'name': map['ticket_name'] as String? ?? '',
            'created_at':
                map['ticket_created_at']?.toString() ??
                DateTime.now().toIso8601String(),
            'updated_at':
                map['ticket_updated_at']?.toString() ??
                DateTime.now().toIso8601String(),
            'target_entry_group_ids':
                (map['target_entry_group_ids'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [],
          }
        : null,
  };
}

mixin _EventRepositoryApplicationQueries on _SupabaseEventContext {
  /// Fetches applications for a specific event.
  Future<List<EventApplication>> getApplicationsByEventId(
    String eventId,
  ) async {
    Log.d('getApplicationsByEventId called | id: $eventId');
    try {
      final data =
          await supabaseClient.rpc<dynamic>(
                'get_event_applications_with_user',
                params: {'p_event_id': eventId},
              )
              as List;
      final result = data
          .map(
            (json) => EventApplication.fromJson(
              mapEventApplicationRpcRow(json as Map<String, dynamic>),
            ),
          )
          .toList();
      return result;
    } catch (e, st) {
      Log.e('❌ [EventRepo] getApplicationsByEventId Error', e, st);
      rethrow;
    }
  }

  /// Fetches a single event application by its ID, including the applicant's
  /// full user profile. Used by the application detail page.
  Future<EventApplication?> getApplicationById(String applicationId) async {
    Log.d('getApplicationById called | id: $applicationId');
    try {
      // Fix #2250: use partner_visible_user_profiles view — DB-enforced column
      // restriction per PM #1141 and PIPA §17. View exposes birth_year (derived),
      // not birth_date, ensuring exact DOB never reaches partner devices.
      final response = await supabaseClient
          .from('event_applications')
          .select(
            '*, user:partner_visible_user_profiles(id, username, birth_year, is_verified, profile_image_url)',
          )
          .eq('id', applicationId)
          .maybeSingle();
      if (response == null) return null;
      return EventApplication.fromJson(response);
    } catch (e, st) {
      Log.e('❌ [EventRepo] getApplicationById Error', e, st);
      rethrow;
    }
  }

  /// Fetches a single application with full event, ticket, and submission data
  /// for the purchase history detail page.
  Future<EventApplication?> getPurchaseHistoryDetailById(
    String applicationId,
  ) async {
    Log.d('getPurchaseHistoryDetailById called | id: $applicationId');
    try {
      final response = await supabaseClient
          .from('event_applications')
          .select(
            '*, '
            'event:events(*, party:parties(*, location:locations(*))), '
            'ticket:tickets(*)',
          )
          .eq('id', applicationId)
          .maybeSingle();
      if (response == null) return null;
      return EventApplication.fromJson(response);
    } catch (e, st) {
      Log.e('❌ [EventRepo] getPurchaseHistoryDetailById Error', e, st);
      rethrow;
    }
  }

  /// Fetches the application record for a specific user and event.
  Future<EventApplication?> getApplication({
    required String eventId,
    required String userId,
  }) async {
    Log.d('getApplication called | event: $eventId, user: $userId');
    try {
      final response = await supabaseClient
          .from('event_applications')
          .select()
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return EventApplication.fromJson(response);
    } catch (e, st) {
      Log.e('❌ [EventRepo] getApplication Error', e, st);
      rethrow;
    }
  }

  /// Checks if a user has already applied for an event.
  Future<bool> checkApplicationStatus({
    required String eventId,
    required String userId,
  }) async {
    final app = await getApplication(eventId: eventId, userId: userId);
    return app != null && app.status != 'rejected' && app.status != 'cancelled';
  }

  /// Fetches the current user's purchase history.
  Future<List<EventApplication>> getMyPurchaseHistory(String userId) async {
    Log.d('getMyPurchaseHistory called | userId: $userId');
    try {
      final data = await supabaseClient
          .from('event_applications')
          .select(
            '*, '
            'event:events(*, party:parties(*, location:locations(*))), '
            'ticket:tickets(*)',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final result = data.map((json) {
        return EventApplication.fromJson(json);
      }).toList();

      Log.d('getMyPurchaseHistory success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [EventRepo] getMyPurchaseHistory Error', e, st);
      rethrow;
    }
  }

  /// Fetches the current user's active tickets (paid/approved only).
  Future<List<EventApplication>> getMyTickets(String userId) async {
    Log.d('getMyTickets called | userId: $userId');
    try {
      // Fix #2123: include match_results_viewed_at for EventOngoingBanner phase
      // resolution — null=resultsUnviewed, set=resultsViewed.
      final data = await supabaseClient
          .from('event_applications')
          .select(
            'id, event_id, ticket_id, user_id, status, created_at, '
            'updated_at, payment_id, payment_amount, refund_status, '
            'rejection_reason, paid_at, refunded_at, cancellation_reason, '
            'match_results_viewed_at, '
            'event:events(*, party:parties(*, location:locations(*))), '
            'ticket:tickets(*)',
          )
          .eq('user_id', userId)
          .inFilter('status', ['paid', 'approved'])
          .order('created_at', ascending: false);
      final result = data.map((json) {
        return EventApplication.fromJson(json);
      }).toList();

      Log.d('getMyTickets success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [EventRepo] getMyTickets Error', e, st);
      rethrow;
    }
  }
}
