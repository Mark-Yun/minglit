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
}
