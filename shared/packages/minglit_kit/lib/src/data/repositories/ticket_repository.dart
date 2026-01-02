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
    try {
      final data = await _supabase
          .from('tickets')
          .select()
          .eq('event_id', eventId)
          .order('price', ascending: true);

      return (data as List<dynamic>)
          .map((json) => Ticket.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      Log.e('getTicketsByEventId failed', e, st);
      rethrow;
    }
  }

  /// Fetches all tickets associated with any event of a specific party.
  Future<List<Ticket>> getTicketsByPartyId(String partyId) async {
    try {
      final data = await _supabase
          .from('tickets')
          .select('*, events!inner(party_id)')
          .eq('events.party_id', partyId)
          .order('created_at', ascending: true);

      return (data as List<dynamic>)
          .map((json) => Ticket.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      Log.e('getTicketsByPartyId failed', e, st);
      rethrow;
    }
  }

  /// Fetches default ticket templates for a specific party.
  Future<List<Ticket>> getDefaultTicketsByPartyId(String partyId) async {
    try {
      final data = await _supabase
          .from('tickets')
          .select()
          .eq('party_id', partyId)
          .filter('event_id', 'is', null)
          .order('created_at', ascending: true);

      return (data as List<dynamic>)
          .map((json) => Ticket.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      Log.e('getDefaultTicketsByPartyId failed', e, st);
      rethrow;
    }
  }

  /// Creates a new ticket.
  Future<Ticket> createTicket(Ticket ticket) async {
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

      return Ticket.fromJson(data);
    } catch (e, st) {
      Log.e('createTicket failed: ${ticket.name}', e, st);
      rethrow;
    }
  }
}
