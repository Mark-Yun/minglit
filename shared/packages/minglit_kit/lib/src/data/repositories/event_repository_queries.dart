part of 'event_repository.dart';

mixin _EventRepositoryQueries on _SupabaseEventContext {
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
      final result = data.map((json) {
        final map = json as Map<String, dynamic>;
        // RPC returns flat columns: application_id, event_id, ticket_id,
        // user_id, payment_id, payment_amount, status, created_at, updated_at,
        // user_name, user_phone

        // Map to EventApplication model format
        // (which expects 'id' not 'application_id')
        final appMap = <String, dynamic>{
          'id': map['application_id'],
          'event_id': map['event_id'],
          'ticket_id': map['ticket_id'],
          'user_id': map['user_id'],
          'payment_id': map['payment_id'],
          'payment_amount': map['payment_amount'],
          'status': map['status'],
          'created_at': map['created_at'],
          'updated_at': map['updated_at'],
          'refund_status': map['refund_status'] ?? 'none',
          // Build nested 'user' object from flat RPC columns
          'user': (map['user_name'] != null || map['user_phone'] != null)
              ? {
                  'id': map['user_id'],
                  'name': map['user_name'],
                  'username': '',
                  'phone_number': map['user_phone'],
                }
              : null,
          'submission': null, // Not returned by RPC
        };
        return EventApplication.fromJson(appMap);
      }).toList();
      return result;
    } catch (e, st) {
      Log.e('❌ [EventRepo] getApplicationsByEventId Error', e, st);
      rethrow;
    }
  }

  /// Fetches events based on a specific curation type.
  Future<List<Event>> getEventsByType({
    required EventFeedType type,
    double? latitude,
    double? longitude,
    int limit = 10,
    Set<String>? blockedPartnerIds,
  }) async {
    Log.d('getEventsByType called | type: $type');
    try {
      // 1. Base Query with Relations
      var selectQuery =
          '*, party:parties!inner(*, location:locations(*), partner:partners(*)), '
          'entryGroups:entry_groups(*), tickets(*)';

      // Special case for Early Bird: filter by ticket name
      if (type == EventFeedType.earlyBird) {
        selectQuery =
            '*, party:parties!inner(*, location:locations(*), partner:partners(*)), '
            'entryGroups:entry_groups(*), tickets!inner(*)';
      }

      dynamic query = supabaseClient.from('events').select(selectQuery);

      // 2. Common Filters
      // ignore: avoid_dynamic_calls, Reason: Supabase builder chaining
      query = query.eq('status', 'scheduled');
      // ignore: avoid_dynamic_calls, Reason: Supabase builder chaining
      query = query.gte('start_time', DateTime.now().toIso8601String());
      // ignore: avoid_dynamic_calls, Reason: Supabase builder chaining
      query = query.eq('party.visibility', 'public');

      // 3. Early Bird Filter
      if (type == EventFeedType.earlyBird) {
        // ignore: avoid_dynamic_calls, Reason: Supabase builder chaining
        query = query.ilike('tickets.name', '%얼리버드%');
      }

      // 4. Sorting Strategy
      switch (type) {
        case EventFeedType.newArrivals:
          // ignore: avoid_dynamic_calls, Reason: Supabase builder chaining
          query = query.order('created_at', ascending: false);
        case EventFeedType.closingSoon:
          // ignore: avoid_dynamic_calls, Reason: Supabase builder chaining
          query = query.order('start_time', ascending: true);
        case EventFeedType.nearest:
          // ignore: avoid_dynamic_calls, Reason: Supabase builder chaining
          query = query.order('start_time', ascending: true);
        case EventFeedType.earlyBird:
          // ignore: avoid_dynamic_calls, Reason: Supabase builder chaining
          query = query.order('start_time', ascending: true);
        case EventFeedType.aiRecommended:
          // ignore: avoid_dynamic_calls, Reason: Supabase builder chaining
          query = query.order('created_at', ascending: false);
      }

      final queryLimit =
          blockedPartnerIds != null && blockedPartnerIds.isNotEmpty
          ? (limit * 2).clamp(limit, 30)
          : limit;
      final data =
          await (query as PostgrestTransformBuilder).limit(queryLimit) as List;
      var result = data.map((json) {
        return Event.fromJson(json as Map<String, dynamic>);
      }).toList();

      if (blockedPartnerIds != null && blockedPartnerIds.isNotEmpty) {
        result = result
            .where(
              (e) => !blockedPartnerIds.contains(e.party?.partner?.id),
            )
            .take(limit)
            .toList();
      }

      Log.d('getEventsByType success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [EventRepo] getEventsByType Error', e, st);
      rethrow;
    }
  }

  /// Fetches a single event by ID with all relations.
  Future<Event> getEventById(String eventId) async {
    Log.d('getEventById called | id: $eventId');
    try {
      final data = await supabaseClient
          .from('events')
          .select(
            '*, party:parties(*, location:locations(*), partner:partners(*)), '
            'entryGroups:entry_groups(*), tickets(*)',
          )
          .eq('id', eventId)
          .single();

      final result = Event.fromJson(data);
      Log.d('getEventById success | title: ${result.title}');
      return result;
    } catch (e, st) {
      Log.e('❌ [EventRepo] getEventById Error', e, st);
      rethrow;
    }
  }

  /// Fetches ticket balance status for a specific event.
  Future<Map<String, bool>> getTicketBalanceStatus(String eventId) async {
    Log.d('getTicketBalanceStatus called | eventId: $eventId');
    try {
      final response = await supabaseClient.rpc<List<dynamic>?>(
        'get_event_ticket_balance_status',
        params: {'p_event_id': eventId},
      );

      final result = <String, bool>{};
      for (final item in response ?? const []) {
        if (item is! Map<String, dynamic>) {
          throw FormatException('Expected Map, got ${item.runtimeType}');
        }
        final data = item;
        final ticketId = data['ticket_id'] as String?;
        final allowed = data['allowed'] as bool?;
        if (ticketId != null && allowed != null) {
          result[ticketId] = allowed;
        }
      }

      Log.d('getTicketBalanceStatus success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [EventRepo] getTicketBalanceStatus Error', e, st);
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

  /// Fetches entry group participant counts for a specific event.
  Future<List<Map<String, dynamic>>> getEntryGroupParticipantCounts(
    String eventId,
  ) async {
    try {
      final data =
          await supabaseClient.rpc(
                'get_entry_group_participant_counts',
                params: {'p_event_id': eventId},
              )
              as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } on Exception catch (e, st) {
      Log.e('getEntryGroupParticipantCounts Error', e, st);
      rethrow;
    }
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

  /// [Partner Dashboard]
  /// Counts pending review applications for a specific partner.
  Future<int> getPendingApplicationCount(String partnerId) async {
    try {
      // Query verification_submissions joined with applications -> events
      // But RLS might restrict access. Assuming Partner has permission.
      final res = await supabaseClient
          .from('verification_submissions')
          .select('id')
          .eq('partner_id', partnerId)
          .eq('status', 'pending')
          .count(CountOption.exact);

      return res.count;
    } on Exception catch (e, st) {
      Log.e('❌ [EventRepo] getPendingApplicationCount Error', e, st);
      return 0; // Fail safe
    }
  }

  /// Fetches AI-powered personalized event recommendations.
  Future<List<Map<String, dynamic>>> getPersonalizedRecommendations({
    required String userId,
    int limit = 10,
  }) async {
    Log.d('getPersonalizedRecommendations called | userId: $userId');
    try {
      final response = await supabaseClient.rpc<List<dynamic>>(
        'get_personalized_recommendations',
        params: {'p_user_id': userId, 'p_limit': limit},
      );

      final result = response
          .map((item) => item as Map<String, dynamic>)
          .toList();

      Log.d('getPersonalizedRecommendations success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [EventRepo] getPersonalizedRecommendations Error', e, st);
      rethrow;
    }
  }

  /// Fetches events within a geographic radius.
  Future<List<Map<String, dynamic>>> getEventsWithinRadius({
    required double latitude,
    required double longitude,
    int radiusMeters = 5000,
    int limit = 20,
  }) async {
    Log.d(
      'getEventsWithinRadius called | lat: $latitude, lng: $longitude, '
      'radius: $radiusMeters',
    );
    try {
      final response = await supabaseClient.rpc<List<dynamic>>(
        'get_events_within_radius',
        params: {
          'p_lat': latitude,
          'p_lng': longitude,
          'p_radius_meters': radiusMeters,
          'p_limit': limit,
        },
      );

      final result = response
          .map((item) => item as Map<String, dynamic>)
          .toList();

      Log.d('getEventsWithinRadius success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [EventRepo] getEventsWithinRadius Error', e, st);
      rethrow;
    }
  }

  /// Fetches bulk eligibility data for a user (profile + verified status).
  Future<Map<String, dynamic>> getBulkEligibilityData({
    required String userId,
  }) async {
    Log.d('getBulkEligibilityData called | userId: $userId');
    try {
      final response = await supabaseClient.rpc<Map<String, dynamic>>(
        'get_bulk_eligibility_data',
        params: {'p_user_id': userId},
      );

      Log.d('getBulkEligibilityData success');
      return response;
    } catch (e, st) {
      Log.e('❌ [EventRepo] getBulkEligibilityData Error', e, st);
      rethrow;
    }
  }

  /// [Partner Dashboard]
  /// Fetches events scheduled for today for a specific partner.
  Future<List<Event>> getTodayEvents(String partnerId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(
        now.year,
        now.month,
        now.day,
      ).toIso8601String();
      final endOfDay = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
      ).toIso8601String();

      final data = await supabaseClient
          .from('events')
          .select('*, party:parties!inner(*)')
          .eq('party.partner_id', partnerId)
          .gte('start_time', startOfDay)
          .lte('start_time', endOfDay)
          .order('start_time');
      return data.map((json) {
        return Event.fromJson(json);
      }).toList();
    } catch (e, st) {
      Log.e('❌ [EventRepo] getTodayEvents Error', e, st);
      rethrow;
    }
  }

  /// [Partner Dashboard]
  /// Fetches events scheduled within the next 7 days for a specific partner.
  Future<List<Event>> getUpcomingEvents(String partnerId) async {
    try {
      final now = DateTime.now();
      final nowStr = now.toIso8601String();
      final sevenDaysLater = now.add(const Duration(days: 7)).toIso8601String();

      final data = await supabaseClient
          .from('events')
          .select('*, party:parties!inner(*)')
          .eq('party.partner_id', partnerId)
          .gte('start_time', nowStr)
          .lte('start_time', sevenDaysLater)
          .order('start_time');
      return data.map((json) {
        return Event.fromJson(json);
      }).toList();
    } catch (e, st) {
      Log.e('❌ [EventRepo] getUpcomingEvents Error', e, st);
      rethrow;
    }
  }

  /// [Partner Dashboard]
  /// Fetches events with start_time within the next 3 days for a specific
  /// partner. Used for "마감임박" (closing soon) display on dashboard.
  Future<List<Event>> getClosingSoonEvents(String partnerId) async {
    try {
      final now = DateTime.now();
      final nowStr = now.toIso8601String();
      final threeDaysLater = now.add(const Duration(days: 3)).toIso8601String();

      final data = await supabaseClient
          .from('events')
          .select('*, party:parties!inner(*)')
          .eq('party.partner_id', partnerId)
          .gte('start_time', nowStr)
          .lte('start_time', threeDaysLater)
          .order('start_time');
      return data.map((json) {
        return Event.fromJson(json);
      }).toList();
    } catch (e, st) {
      Log.e('❌ [EventRepo] getClosingSoonEvents Error', e, st);
      rethrow;
    }
  }
}
