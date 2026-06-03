import 'package:minglit_kit/src/data/models/ticket.dart';
import 'package:minglit_kit/src/data/models/ticket_template.dart';
import 'package:minglit_kit/src/logic/providers/supabase_provider.dart';
import 'package:minglit_kit/src/utils/exceptions.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'ticket_repository.g.dart';

/// Provides the [TicketRepository].
@Riverpod(keepAlive: true)
TicketRepository ticketRepository(Ref ref) {
  return TicketRepository(supabase: ref.watch(supabaseClientProvider));
}

/// Repository for ticket and ticket template records.
class TicketRepository {
  /// Creates a [TicketRepository] with a Supabase client.
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

  /// Fetches ticket templates for a specific party.
  Future<List<TicketTemplate>> getTicketTemplatesByPartyId(
    String partyId,
  ) async {
    Log.d('getTicketTemplatesByPartyId called | partyId: $partyId');
    try {
      final data = await _supabase
          .from('ticket_templates')
          .select()
          .eq('party_id', partyId)
          .order('created_at', ascending: true);

      final result = (data as List<dynamic>)
          .map((json) => TicketTemplate.fromJson(json as Map<String, dynamic>))
          .toList();

      Log.d('getTicketTemplatesByPartyId success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('getTicketTemplatesByPartyId failed', e, st);
      rethrow;
    }
  }

  /// Fetches default ticket templates for a specific party.
  /// (Alias for getTicketTemplatesByPartyId for backward compatibility)
  Future<List<TicketTemplate>> getDefaultTicketsByPartyId(
    String partyId,
  ) async {
    return getTicketTemplatesByPartyId(partyId);
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

  /// Fetches a specific ticket template by ID.
  Future<TicketTemplate> getTicketTemplateById(String id) async {
    Log.d('getTicketTemplateById called | id: $id');
    try {
      final data = await _supabase
          .from('ticket_templates')
          .select()
          .eq('id', id)
          .single();

      final result = TicketTemplate.fromJson(data);
      Log.d('getTicketTemplateById success | id: ${result.id}');
      return result;
    } catch (e, st) {
      Log.e('getTicketTemplateById failed', e, st);
      rethrow;
    }
  }

  /// Updates an existing ticket template.
  Future<TicketTemplate> updateTicketTemplate(TicketTemplate template) async {
    Log.d('updateTicketTemplate called | id: ${template.id}');
    try {
      final json = template.toDbJson();

      final response = await _supabase.functions.invoke(
        'partner-manage-party',
        body: {
          'action': 'update_ticket_template',
          'ticket_template_id': template.id,
          'ticket_template': json..remove('party_id'),
        },
      );
      if (response.status != 200) {
        final error = response.data is Map
            ? (response.data as Map)['error'] ??
                  'Failed to update ticket template'
            : 'Failed to update ticket template';
        throw Exception(error);
      }

      final result = await getTicketTemplateById(template.id);
      Log.d('updateTicketTemplate success | id: ${result.id}');
      return result;
    } catch (e, st) {
      Log.e('updateTicketTemplate failed', e, st);
      rethrow;
    }
  }

  /// Creates a new ticket template for a party.
  Future<TicketTemplate> createTicketTemplate(TicketTemplate template) async {
    Log.d('createTicketTemplate called | ticket: ${template.name}');
    try {
      final json = template.toDbJson();

      final response = await _supabase.functions.invoke(
        'partner-manage-party',
        body: {
          'action': 'create_ticket_template',
          'ticket_template': json,
        },
      );
      if (response.status != 200) {
        final error = response.data is Map
            ? (response.data as Map)['error'] ??
                  'Failed to create ticket template'
            : 'Failed to create ticket template';
        throw Exception(error);
      }

      final data = response.data as Map<String, dynamic>;
      final templateId = data['ticket_template_id'] as String;
      final result = await getTicketTemplateById(templateId);
      Log.d('createTicketTemplate success | id: ${result.id}');
      return result;
    } catch (e, st) {
      Log.e('createTicketTemplate failed: ${template.name}', e, st);
      rethrow;
    }
  }

  /// Deletes a ticket template by ID.
  Future<void> deleteTicketTemplate(String id) async {
    Log.d('deleteTicketTemplate called | id: $id');
    try {
      final response = await _supabase.functions.invoke(
        'partner-manage-party',
        body: {
          'action': 'delete_ticket_template',
          'ticket_template_id': id,
        },
      );
      if (response.status != 200) {
        final error = response.data is Map
            ? (response.data as Map)['error'] ??
                  'Failed to delete ticket template'
            : 'Failed to delete ticket template';
        throw Exception(error);
      }
      Log.d('deleteTicketTemplate success | id: $id');
    } catch (e, st) {
      Log.e('deleteTicketTemplate failed: $id', e, st);
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

      final response = await _supabase.functions.invoke(
        'partner-manage-event',
        body: {
          'action': 'create_ticket',
          'ticket': json,
        },
      );
      if (response.status != 200) {
        final error = response.data is Map
            ? (response.data as Map)['error'] ?? 'Failed to create ticket'
            : 'Failed to create ticket';
        throw Exception(error);
      }

      final data = response.data as Map<String, dynamic>;
      final ticketId = data['ticket_id'] as String;
      final result = await getTicketById(ticketId);
      Log.d('createTicket success | id: ${result.id}');
      return result;
    } catch (e, st) {
      Log.e('createTicket failed: ${ticket.name}', e, st);
      rethrow;
    }
  }

  /// Updates an existing ticket.
  /// Validates that quantity cannot be less than sold_count.
  Future<Ticket> updateTicket(Ticket ticket) async {
    Log.d('updateTicket called | ticket: ${ticket.id}');
    try {
      // 1. Fetch current state to check sold_count
      final current = await getTicketById(ticket.id);

      if (ticket.quantity < current.soldCount) {
        throw MinglitUserException(
          '전체 수량(${ticket.quantity}매)은 '
          '이미 판매된 수량(${current.soldCount}매)보다 적을 수 없습니다.',
        );
      }

      final eventId = ticket.eventId;
      if (eventId == null || eventId.isEmpty) {
        throw const MinglitUserException('이벤트 정보가 없는 티켓은 수정할 수 없습니다.');
      }

      final json = ticket.toJson()
        ..remove('created_at')
        ..remove('updated_at') // moddatetime trigger handles this
        ..remove('sold_count'); // sold_count is managed by system

      final response = await _supabase.functions.invoke(
        'partner-manage-event',
        body: {
          'action': 'update_tickets',
          'event_id': eventId,
          'tickets': [
            {
              ...json,
              'ticket_id': ticket.id,
            },
          ],
        },
      );
      if (response.status != 200) {
        final error = response.data is Map
            ? (response.data as Map)['error'] ?? 'Failed to update ticket'
            : 'Failed to update ticket';
        throw Exception(error);
      }

      final result = await getTicketById(ticket.id);
      Log.d('updateTicket success | id: ${result.id}');
      return result;
    } catch (e, st) {
      if (e is MinglitException) rethrow;
      Log.e('updateTicket failed: ${ticket.id}', e, st);
      rethrow;
    }
  }
}
