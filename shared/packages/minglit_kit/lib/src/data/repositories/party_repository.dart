import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/src/data/models/event.dart';
import 'package:minglit_kit/src/data/models/party.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:path/path.dart' as p;
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

  /// Uploads a party image and returns the public URL.
  Future<String> uploadPartyImage(XFile file, String partnerId) async {
    try {
      final extension = p.extension(file.name);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // Structure: partner_id/timestamp_filename
      final path = '$partnerId/$timestamp$extension';
      final bytes = await file.readAsBytes();

      await _supabase.storage
          .from('party-assets')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      return _supabase.storage.from('party-assets').getPublicUrl(path);
    } catch (e, st) {
      Log.e('❌ [PartyRepo] uploadPartyImage Error', e, st);
      rethrow;
    }
  }

  /// Fetches a single party by ID.
  Future<Party> getPartyById(String partyId) async {
    try {
      final data = await _supabase
          .from('parties')
          .select()
          .eq('id', partyId)
          .single();

      return Party.fromJson(data);
    } catch (e, st) {
      Log.e('❌ [PartyRepo] getPartyById Error', e, st);
      rethrow;
    }
  }

  /// Fetches all active parties.
  Future<List<Party>> getParties() async {
    try {
      final data = await _supabase
          .from('parties')
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return (data as List<dynamic>)
          .map((json) => Party.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      Log.e('❌ [PartyRepo] getParties Error', e, st);
      rethrow;
    }
  }

  /// Fetches parties for a specific partner.
  Future<List<Party>> getPartiesByPartnerId(String partnerId) async {
    try {
      final data = await _supabase
          .from('parties')
          .select()
          .eq('partner_id', partnerId)
          .order('created_at', ascending: false);

      return (data as List<dynamic>)
          .map((json) => Party.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      Log.e('❌ [PartyRepo] getPartiesByPartnerId Error', e, st);
      rethrow;
    }
  }

  /// Fetches upcoming events for a specific party.
  Future<List<Event>> getEventsByPartyId(String partyId) async {
    try {
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
    } catch (e, st) {
      Log.e('❌ [PartyRepo] getEventsByPartyId Error', e, st);
      rethrow;
    }
  }

  /// Fetches a single event by ID.
  Future<Event> getEventById(String eventId) async {
    try {
      final data = await _supabase
          .from('events')
          .select()
          .eq('id', eventId)
          .single();

      return Event.fromJson(data);
    } catch (e, st) {
      Log.e('❌ [PartyRepo] getEventById Error', e, st);
      rethrow;
    }
  }

  /// Creates a new party.
  Future<Party> createParty(Party party) async {
    try {
      final json = party.toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at');

      final data = await _supabase
          .from('parties')
          .insert(json)
          .select()
          .single();

      return Party.fromJson(data);
    } catch (e, st) {
      Log.e('❌ [PartyRepo] createParty Error', e, st);
      rethrow;
    }
  }

  /// Updates an existing party.
  Future<Party> updateParty(Party party) async {
    try {
      final json = party.toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at');

      final data = await _supabase
          .from('parties')
          .update(json)
          .eq('id', party.id)
          .select()
          .single();

      return Party.fromJson(data);
    } catch (e, st) {
      Log.e('❌ [PartyRepo] updateParty Error', e, st);
      rethrow;
    }
  }

  /// Updates only the status of a party.
  Future<void> updatePartyStatus(String partyId, String status) async {
    try {
      await _supabase
          .from('parties')
          .update({'status': status})
          .eq('id', partyId);
    } catch (e, st) {
      Log.e('❌ [PartyRepo] updatePartyStatus Error', e, st);
      rethrow;
    }
  }

  /// Updates the location of a party.
  Future<void> updatePartyLocation(String partyId, String locationId) async {
    try {
      await _supabase
          .from('parties')
          .update({'location_id': locationId})
          .eq('id', partyId);
    } catch (e, st) {
      Log.e('❌ [PartyRepo] updatePartyLocation Error', e, st);
      rethrow;
    }
  }

  /// Creates a new event for a party.
  Future<Event> createEvent(Event event) async {
    try {
      final json = event.toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at')
        ..remove('party')
        ..remove('location');

      final data = await _supabase
          .from('events')
          .insert(json)
          .select()
          .single();

      return Event.fromJson(data);
    } catch (e, st) {
      Log.e('❌ [PartyRepo] createEvent Error', e, st);
      rethrow;
    }
  }

  /// Updates an existing event.
  Future<Event> updateEvent(Event event) async {
    try {
      final json = event.toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at')
        ..remove('party')
        ..remove('location');

      final data = await _supabase
          .from('events')
          .update(json)
          .eq('id', event.id)
          .select()
          .single();

      return Event.fromJson(data);
    } catch (e, st) {
      Log.e('❌ [PartyRepo] updateEvent Error', e, st);
      rethrow;
    }
  }

  /// Updates only the status of an event.
  Future<void> updateEventStatus(String eventId, String status) async {
    try {
      await _supabase
          .from('events')
          .update({'status': status})
          .eq('id', eventId);
    } catch (e, st) {
      Log.e('❌ [PartyRepo] updateEventStatus Error', e, st);
      rethrow;
    }
  }
}
