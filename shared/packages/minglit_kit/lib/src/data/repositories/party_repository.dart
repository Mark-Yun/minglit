import 'package:minglit_kit/src/data/models/event.dart';
import 'package:minglit_kit/src/data/models/party.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'party_repository.g.dart';

/// Provider for PartyRepository.
@Riverpod(keepAlive: true)
PartyRepository partyRepository(Ref ref) {
  return PartyRepository();
}

/// Repository for Party-related data operations.
class PartyRepository {
  PartyRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Fetches all active parties.
  Future<List<Party>> getParties() async {
    final data = await _supabase
        .from('parties')
        .select()
        .eq('status', 'active')
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((json) => Party.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetches parties for a specific partner.
  Future<List<Party>> getPartiesByPartnerId(String partnerId) async {
    final data = await _supabase
        .from('parties')
        .select()
        .eq('partner_id', partnerId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((json) => Party.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetches upcoming events for a specific party.
  Future<List<Event>> getEventsByPartyId(String partyId) async {
    final data = await _supabase
        .from('events')
        .select()
        .eq('party_id', partyId)
        .gte(
          'start_time',
          DateTime.now().toIso8601String(),
        ) // Future events only
        .order('start_time', ascending: true);

    return (data as List<dynamic>)
        .map((json) => Event.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
