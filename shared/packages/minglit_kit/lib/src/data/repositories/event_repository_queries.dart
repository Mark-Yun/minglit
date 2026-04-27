part of 'event_repository.dart';

mixin _EventRepositoryQueries on _SupabaseEventContext {
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
      // ignore: avoid_dynamic_calls, Reason: Supabase builder chaining
      query = query.inFilter('status', ['scheduled', 'active', 'ongoing']);
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

  /// Fetches entry group participant counts for a specific event.
  Future<List<Map<String, dynamic>>> getEntryGroupParticipantCounts(
    String eventId,
  ) async {
    try {
      final data =
          await supabaseClient.rpc<dynamic>(
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
}
