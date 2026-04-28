part of 'event_repository.dart';

mixin _EventRepositoryFeedQueries on _SupabaseEventContext {
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

  /// Fetches server-side event feed via the user-event-feed Edge Function (#614).
  ///
  /// Returns the full response map with `events`, `has_more`, and `next_cursor`.
  Future<Map<String, dynamic>> getEventFeed({
    required String sortBy,
    Map<String, dynamic>? filters,
    int limit = 20,
    String? cursor,
  }) async {
    Log.d('getEventFeed called | sortBy: $sortBy, limit: $limit');
    try {
      final response = await supabaseClient.functions.invoke(
        'user-event-feed',
        body: {
          'sort_by': sortBy,
          'filters': ?filters,
          'limit': limit,
          'cursor': ?cursor,
        },
      );
      if (response.status != 200) {
        throw Exception('Failed to fetch event feed: ${response.data}');
      }
      final data = response.data as Map<String, dynamic>;
      Log.d(
        'getEventFeed success | count: ${(data['events'] as List?)?.length ?? 0}',
      );
      return data;
    } catch (e, st) {
      Log.e('[EventRepo] getEventFeed Error', e, st);
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

  /// Fetches today's active events for a user (Event Now Bar).
  ///
  /// Returns events where the user is a participant and the event is within
  /// the active window: start_time - 3h <= now AND end_time >= start of today.
  ///
  /// The end_time lower bound is the start of today (not `now`) so that
  /// already-ended events still appear in the bar with the "ended" state,
  /// letting users see match results etc. after the event concludes.
  ///
  /// Fix #1212: Changed end_time lower bound from `now` to `startOfDay` so
  /// that events which have already ended today are still returned and shown
  /// as "종료됨" rather than disappearing from the nowbar entirely.
  ///
  /// Includes cancelled events (shown as "cancelled" in the now bar).
  /// Excludes refunded participants via event_applications.refund_status.
  Future<List<TodayActiveEvent>> getTodayActiveEventsForUser(
    String userId,
  ) async {
    Log.d('getTodayActiveEventsForUser called | userId: $userId');
    try {
      final now = DateTime.now();
      final threeHoursFromNow = now.add(const Duration(hours: 3));
      // Fix #1212: use start-of-day so that already-ended events still appear
      // in the nowbar with the "종료됨" state (match results remain visible).
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Query events where this user has a participant record
      // and the event is within the active window.
      final data = await supabaseClient
          .from('events')
          .select(
            '*, '
            'participant:event_participants!inner(id, user_id, status), '
            'party:parties(*, location:locations(*), partner:partners(*)), '
            'tickets(*)',
          )
          .eq('participant.user_id', userId)
          .lte('start_time', threeHoursFromNow.toIso8601String())
          .gte('end_time', startOfDay.toIso8601String())
          .order('start_time');

      final events = <TodayActiveEvent>[];
      for (final json in data) {
        final map = json;
        // Extract participant status from the joined data
        final participants = map['participant'] as List<dynamic>?;
        final participantStatus =
            (participants?.firstOrNull as Map<String, dynamic>?)?['status']
                as String? ??
            'ticket_issued';

        // Remove participant array before parsing Event
        // (Event model doesn't include it)
        final eventMap = Map<String, dynamic>.from(map)..remove('participant');
        final event = Event.fromJson(eventMap);
        events.add(
          TodayActiveEvent(event: event, participantStatus: participantStatus),
        );
      }

      // Filter out refunded participants by checking event_applications
      if (events.isNotEmpty) {
        final appData = await supabaseClient
            .from('event_applications')
            .select('event_id, refund_status')
            .eq('user_id', userId)
            .inFilter(
              'event_id',
              events.map((e) => e.event.id).toList(),
            );

        final refundedEventIds = <String>{};
        for (final app in appData) {
          final refundStatus = app['refund_status'] as String?;
          if (refundStatus == 'refunded') {
            refundedEventIds.add(app['event_id'] as String);
          }
        }

        if (refundedEventIds.isNotEmpty) {
          events.removeWhere((e) => refundedEventIds.contains(e.event.id));
        }
      }

      Log.d('getTodayActiveEventsForUser success | count: ${events.length}');
      return events;
    } catch (e, st) {
      Log.e('❌ [EventRepo] getTodayActiveEventsForUser Error', e, st);
      rethrow;
    }
  }

  // Fix #1534: search_events_pgroonga 직접 호출은 events 행만 반환해 party.title/tickets 누락 — ID 목록 조회 후 relations 포함 재조회
  Future<List<Event>> searchEvents(String query) async {
    Log.d('searchEvents called | queryLength: ${query.length}');
    if (query.isEmpty) return [];
    try {
      // Step 1: PGroonga RPC — ordered event IDs with block/visibility filters applied
      final rpcResult = await supabaseClient.rpc<List<dynamic>>(
        'search_events_pgroonga',
        params: {'query': query},
      );
      final ids = rpcResult
          .map((item) => (item as Map<String, dynamic>)['id'] as String)
          .toList();

      if (ids.isEmpty) return [];

      // Step 2: PostgREST with full relations — preserves RPC ordering via inFilter
      final data = await supabaseClient
          .from('events')
          .select(
            '*, party:parties(*, location:locations(*), partner:partners(*)), '
            'entryGroups:entry_groups(*), tickets(*)',
          )
          .inFilter('id', ids);

      final byId = {
        for (final json in data as List)
          (json as Map<String, dynamic>)['id'] as String: Event.fromJson(json),
      };
      // Restore PGroonga relevance order
      final result = ids.map((id) => byId[id]).whereType<Event>().toList();

      Log.d('searchEvents success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [EventRepo] searchEvents Error', e, st);
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
    int offset = 0,
  }) async {
    Log.d('getEventsByType called | type: $type');
    try {
      // 1. Base Query with Relations
      var selectQuery =
          '*, party:parties!inner(*, location:locations(*), '
          'partner:partners(*)), '
          'entryGroups:entry_groups(*), tickets(*)';

      // Special case for Early Bird: filter by ticket name
      if (type == EventFeedType.earlyBird) {
        selectQuery =
            '*, party:parties!inner(*, location:locations(*), '
            'partner:partners(*)), '
            'entryGroups:entry_groups(*), tickets!inner(*)';
      }

      dynamic query = supabaseClient.from('events').select(selectQuery);

      // 2. Common Filters
      // Fix #1941: include active/ongoing so events within 30-min pre-checkin
      // window stay visible in the feed (status machine added in migration
      // 20260405000001).
      // Fix #1941 v2: ongoing events have start_time <= now, so gte('start_time')
      // would exclude them. Use gt('end_time') instead — ongoing events are still
      // running (end_time > now) and end_time is NOT NULL per schema.
      // ignore: avoid_dynamic_calls, Reason: Supabase builder chaining
      query = query.inFilter('status', ['scheduled', 'active', 'ongoing']);
      // ignore: avoid_dynamic_calls, Reason: Supabase builder chaining
      query = query.gt('end_time', DateTime.now().toIso8601String());
      // ignore: avoid_dynamic_calls, Reason: Supabase builder chaining
      query = query.eq('party.visibility', 'public');

      // 3. Early Bird Filter
      if (type == EventFeedType.earlyBird) {
        // ignore: avoid_dynamic_calls, Reason: Supabase builder chaining
        query = query.ilike('tickets.name', '%얼리버드%');
      }

      // 4. Sorting Strategy
      // Fix #193: Add `id` tiebreaker to all ORDER BY for deterministic
      // offset-based pagination — prevents duplicate/skipped rows across pages.
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
      // ignore: avoid_dynamic_calls, Reason: Supabase builder chaining
      query = query.order('id', ascending: true);

      final queryLimit =
          blockedPartnerIds != null && blockedPartnerIds.isNotEmpty
          ? (limit * 2).clamp(limit, 30)
          : limit;
      final data =
          await (query as PostgrestTransformBuilder).range(
                offset,
                offset + queryLimit - 1,
              )
              as List;
      var result = data.map((json) {
        return Event.fromJson(json as Map<String, dynamic>);
      }).toList();

      if (blockedPartnerIds != null && blockedPartnerIds.isNotEmpty) {
        result = result
            .where((e) => !blockedPartnerIds.contains(e.party?.partner?.id))
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
}
