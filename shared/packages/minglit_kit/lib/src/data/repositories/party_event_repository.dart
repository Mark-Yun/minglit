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

      final data = await supabaseClient
          .from('events')
          .insert(eventJson)
          .select()
          .single();

      final createdEvent = Event.fromJson(data);

      // Create associated entry groups if provided
      final eventGroups = event.entryGroups;
      if (eventGroups != null && eventGroups.isNotEmpty) {
        final groupsJson = eventGroups
            .map((g) => g.copyWith(eventId: createdEvent.id).toDbJson())
            .toList();
        // minglit_lints: allow-supabase-write — reason: EF migration pending (Phase 2 partner-side, tracked in #2392)
        await supabaseClient.from('entry_groups').insert(groupsJson);
      }

      // Create associated tickets if provided
      final eventTickets = event.tickets;
      if (eventTickets != null && eventTickets.isNotEmpty) {
        final ticketsJson = eventTickets
            .map((t) => t.toDbJson(eventId: createdEvent.id))
            .toList();

        // minglit_lints: allow-supabase-write — reason: EF migration pending (Phase 2 partner-side, tracked in #2392)
        await supabaseClient.from('tickets').insert(ticketsJson);
      }

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

      final data = await supabaseClient
          .from('events')
          .update(json)
          .eq('id', event.id)
          .select()
          .single();

      final result = Event.fromJson(data);
      Log.d('updateEvent success | id: ${result.id}');
      return result;
    } catch (e, st) {
      Log.e('❌ [PartyRepo] updateEvent Error', e, st);
      rethrow;
    }
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
