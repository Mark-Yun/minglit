part of 'event_repository.dart';

mixin _EventRepositoryCheckinQueries on _SupabaseEventContext {
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
