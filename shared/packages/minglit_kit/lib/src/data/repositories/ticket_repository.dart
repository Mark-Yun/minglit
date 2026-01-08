import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'ticket_repository.g.dart';

@Riverpod(keepAlive: true)
TicketRepository ticketRepository(Ref ref) {
  return TicketRepository();
}

class TicketRepository {
  TicketRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Fetches tickets for a specific event.
  Future<List<Ticket>> getTicketsByEventId(String eventId) async {
    Log.d('getTicketsByEventId called | eventId: $eventId');
    try {
      final data = await _supabase
          .from('tickets')
          .select()
          .eq('event_id', eventId)
          .order('price', ascending: true);

      final result = (data as List<dynamic>)
          .map((json) => Ticket.fromJson(json as Map<String, dynamic>))
          .toList();

      Log.d('getTicketsByEventId success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('getTicketsByEventId failed', e, st);
      rethrow;
    }
  }

  /// Fetches all tickets associated with any event of a specific party.
  Future<List<Ticket>> getTicketsByPartyId(String partyId) async {
    Log.d('getTicketsByPartyId called | partyId: $partyId');
    try {
      final data = await _supabase
          .from('tickets')
          .select('*, events!inner(party_id)')
          .eq('events.party_id', partyId)
          .order('created_at', ascending: true);

      final result = (data as List<dynamic>)
          .map((json) => Ticket.fromJson(json as Map<String, dynamic>))
          .toList();

      Log.d('getTicketsByPartyId success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('getTicketsByPartyId failed', e, st);
      rethrow;
    }
  }

  /// Fetches default ticket templates for a specific party.
  Future<List<Ticket>> getDefaultTicketsByPartyId(String partyId) async {
    Log.d('getDefaultTicketsByPartyId called | partyId: $partyId');
    try {
      final data = await _supabase
          .from('tickets')
          .select()
          .eq('party_id', partyId)
          .filter('event_id', 'is', null)
          .order('created_at', ascending: true);

      final result = (data as List<dynamic>)
          .map((json) => Ticket.fromJson(json as Map<String, dynamic>))
          .toList();

      Log.d('getDefaultTicketsByPartyId success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('getDefaultTicketsByPartyId failed', e, st);
      rethrow;
    }
  }

  /// Fetches a specific ticket by ID.
  Future<Ticket> getTicketById(String id) async {
    Log.d('getTicketById called | id: $id');
    try {
      final data = await _supabase
          .from('tickets')
          .select()
          .eq('id', id)
          .single();

      final result = Ticket.fromJson(data);
      Log.d('getTicketById success | id: ${result.id}');
      return result;
    } catch (e, st) {
      Log.e('getTicketById failed', e, st);
      rethrow;
    }
  }

  /// Creates a new ticket.
  Future<Ticket> createTicket(Ticket ticket) async {
    Log.d('createTicket called | ticket: ${ticket.name}');
    try {
      final json = ticket.toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at')
        ..remove('sold_count');

      final data = await _supabase
          .from('tickets')
          .insert(json)
          .select()
          .single();

      final result = Ticket.fromJson(data);
      Log.d('createTicket success | id: ${result.id}');
      return result;
    } catch (e, st) {
      Log.e('createTicket failed: ${ticket.name}', e, st);
      rethrow;
    }
  }

  /// Updates an existing ticket.
  Future<Ticket> updateTicket(Ticket ticket) async {
    Log.d('updateTicket called | ticket: ${ticket.id}');
    try {
      final json = ticket.toJson()
        ..remove('created_at')
        ..remove('updated_at') // moddatetime trigger handles this
        ..remove('sold_count'); // usually not updatable directly

      final data = await _supabase
          .from('tickets')
          .update(json)
          .eq('id', ticket.id)
          .select()
          .single();

      final result = Ticket.fromJson(data);
      Log.d('updateTicket success | id: ${result.id}');
      return result;
    } catch (e, st) {
      Log.e('updateTicket failed: ${ticket.id}', e, st);
      rethrow;
    }
  }
}
