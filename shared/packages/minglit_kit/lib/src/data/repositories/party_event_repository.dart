part of 'party_repository.dart';

mixin _PartyEventRepository on _SupabasePartyContext {
  /// Retrieves events for a specific party.
  Future<List<Event>> getEventsByPartyId(String partyId) async {
    try {
      final data =
          await supabaseClient
                  .from('events')
                  .select('*, entry_groups(*), tickets(*)')
                  .eq('party_id', partyId)
                  .order('start_time', ascending: false)
              as List;
      return data.map((e) {
        return Event.fromJson(e as Map<String, dynamic>);
      }).toList();
    } catch (e, st) {
      Log.e('❌ [PartyRepo] getEventsByPartyId Error', e, st);
      rethrow;
    }
  }

  /// Creates a new event for a party.
  Future<Event> createEvent(Event event) async {
    Log.d('createEvent called | partyId: ${event.partyId}');
    try {
      final eventJson = event.toDbJson();

      final body = <String, dynamic>{
        'action': 'create',
        'party_id': event.partyId,
        'event': eventJson..remove('party_id'),
        if (event.entryGroups != null)
          'entry_groups': event.entryGroups!.map((g) {
            final sourceId = g.id.trim();
            final groupJson = g.toDbJson()..remove('event_id');
            if (sourceId.isNotEmpty) {
              groupJson['source_entry_group_id'] = sourceId;
            }
            return groupJson;
          }).toList(),
        if (event.tickets != null)
          'tickets': event.tickets!
              .map(
                (t) => t.toDbJson()..remove('event_id'),
              )
              .toList(),
      };

      final response = await supabaseClient.functions.invoke(
        'partner-manage-event',
        body: body,
      );
      if (response.status != 200) {
        final error = response.data is Map
            ? (response.data as Map)['error'] ?? 'Failed to create event'
            : 'Failed to create event';
        throw Exception(error);
      }

      final data = response.data as Map<String, dynamic>;
      final eventId = data['event_id'] as String;
      final createdEvent = await _getEventById(eventId);
      Log.d('createEvent success | id: ${createdEvent.id}');
      return createdEvent;
    } catch (e, st) {
      Log.e('❌ [PartyRepo] createEvent Error', e, st);
      rethrow;
    }
  }

  /// Updates an existing event.
  Future<Event> updateEvent(Event event) async {
    Log.d('updateEvent called | id: ${event.id}');
    try {
      final json = event.toDbJson();

      final response = await supabaseClient.functions.invoke(
        'partner-manage-event',
        body: {
          'action': 'update',
          'event_id': event.id,
          'event': json
            ..remove('party_id')
            ..remove('location'),
        },
      );
      if (response.status != 200) {
        final error = response.data is Map
            ? (response.data as Map)['error'] ?? 'Failed to update event'
            : 'Failed to update event';
        throw Exception(error);
      }

      final result = await _getEventById(event.id);
      Log.d('updateEvent success | id: ${result.id}');
      return result;
    } catch (e, st) {
      Log.e('❌ [PartyRepo] updateEvent Error', e, st);
      rethrow;
    }
  }

  Future<Event> _getEventById(String eventId) async {
    final data = await supabaseClient
        .from('events')
        .select('*, entry_groups(*), tickets(*)')
        .eq('id', eventId)
        .single();
    return Event.fromJson(data);
  }

  /// Updates only the status of an event.
  // Fix #2393: route through partner-manage-event EF.
  Future<void> updateEventStatus(String eventId, String status) async {
    Log.d('updateEventStatus called | eventId: $eventId, status: $status');
    try {
      final response = await supabaseClient.functions.invoke(
        'partner-manage-event',
        body: {
          'action': 'update_status',
          'event_id': eventId,
          'status': status,
        },
      );
      if (response.status != 200) {
        final error = response.data is Map
            ? (response.data as Map)['error'] ?? 'Failed to update event status'
            : 'Failed to update event status';
        throw Exception(error);
      }
      Log.d('updateEventStatus success');
    } catch (e, st) {
      Log.e('❌ [PartyRepo] updateEventStatus Error', e, st);
      rethrow;
    }
  }

  /// Updates the metadata of an event.
  // Fix #2393: route through partner-manage-event EF.
  Future<void> updateEventMetadata(
    String eventId,
    Map<String, dynamic> metadata,
  ) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'partner-manage-event',
        body: {
          'action': 'update',
          'event_id': eventId,
          'event': {'metadata': metadata},
        },
      );
      if (response.status != 200) {
        final error = response.data is Map
            ? (response.data as Map)['error'] ??
                  'Failed to update event metadata'
            : 'Failed to update event metadata';
        throw Exception(error);
      }
      Log.d('updateEventMetadata success');
    } catch (e, st) {
      Log.e('❌ [PartyRepo] updateEventMetadata Error', e, st);
      rethrow;
    }
  }
}
