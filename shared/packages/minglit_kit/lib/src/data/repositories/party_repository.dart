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
    Log.d(
      'uploadPartyImage called | partnerId: $partnerId, file: ${file.name}',
    );
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

      final url = _supabase.storage.from('party-assets').getPublicUrl(path);
      Log.d('uploadPartyImage success | url: $url');
      return url;
    } catch (e, st) {
      Log.e('❌ [PartyRepo] uploadPartyImage Error', e, st);
      rethrow;
    }
  }

  /// Fetches a single party by ID.
  Future<Party> getPartyById(String partyId) async {
    Log.d('getPartyById called | partyId: $partyId');
    try {
      final data = await _supabase
          .from('parties')
          .select()
          .eq('id', partyId)
          .single();

      final result = Party.fromJson(data);
      Log.d('getPartyById success | title: ${result.title}');
      return result;
    } catch (e, st) {
      Log.e('❌ [PartyRepo] getPartyById Error', e, st);
      rethrow;
    }
  }

  /// Fetches all active parties.
  Future<List<Party>> getParties() async {
    Log.d('getParties called');
    try {
      final data = await _supabase
          .from('parties')
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false);

      final result = (data as List<dynamic>)
          .map((json) => Party.fromJson(json as Map<String, dynamic>))
          .toList();

      Log.d('getParties success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [PartyRepo] getParties Error', e, st);
      rethrow;
    }
  }

  /// Fetches parties for a specific partner.
  Future<List<Party>> getPartiesByPartnerId(String partnerId) async {
    Log.d('getPartiesByPartnerId called | partnerId: $partnerId');
    try {
      final data = await _supabase
          .from('parties')
          .select()
          .eq('partner_id', partnerId)
          .order('created_at', ascending: false);

      final result = (data as List<dynamic>)
          .map((json) => Party.fromJson(json as Map<String, dynamic>))
          .toList();

      Log.d('getPartiesByPartnerId success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [PartyRepo] getPartiesByPartnerId Error', e, st);
      rethrow;
    }
  }

  /// Fetches upcoming events for a specific party.
  Future<List<Event>> getEventsByPartyId(String partyId) async {
    Log.d('getEventsByPartyId called | partyId: $partyId');
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

      final result = (data as List<dynamic>)
          .map((json) => Event.fromJson(json as Map<String, dynamic>))
          .toList();

      Log.d('getEventsByPartyId success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [PartyRepo] getEventsByPartyId Error', e, st);
      rethrow;
    }
  }

  /// Fetches a single event by ID.
  Future<Event> getEventById(String eventId) async {
    Log.d('getEventById called | eventId: $eventId');
    try {
      final data = await _supabase
          .from('events')
          .select()
          .eq('id', eventId)
          .single();

      final result = Event.fromJson(data);
      Log.d('getEventById success | id: ${result.id}');
      return result;
    } catch (e, st) {
      Log.e('❌ [PartyRepo] getEventById Error', e, st);
      rethrow;
    }
  }

  /// Creates a new party.
  Future<Party> createParty(Party party) async {
    Log.d('createParty called | title: ${party.title}');
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

      final result = Party.fromJson(data);
      Log.d('createParty success | id: ${result.id}');
      return result;
    } catch (e, st) {
      Log.e('❌ [PartyRepo] createParty Error', e, st);
      rethrow;
    }
  }

  /// Updates an existing party.
  Future<Party> updateParty(Party party) async {
    Log.d('updateParty called | id: ${party.id}');
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

      final result = Party.fromJson(data);
      Log.d('updateParty success | id: ${result.id}');
      return result;
    } catch (e, st) {
      Log.e('❌ [PartyRepo] updateParty Error', e, st);
      rethrow;
    }
  }

  /// Updates only the status of a party.
  Future<void> updatePartyStatus(String partyId, String status) async {
    Log.d('updatePartyStatus called | partyId: $partyId, status: $status');
    try {
      await _supabase
          .from('parties')
          .update({'status': status})
          .eq('id', partyId);
      Log.d('updatePartyStatus success');
    } catch (e, st) {
      Log.e('❌ [PartyRepo] updatePartyStatus Error', e, st);
      rethrow;
    }
  }

  /// Updates the location of a party.
  Future<void> updatePartyLocation(String partyId, String locationId) async {
    Log.d(
      'updatePartyLocation called | partyId: $partyId, locationId: $locationId',
    );
    try {
      await _supabase
          .from('parties')
          .update({'location_id': locationId})
          .eq('id', partyId);
      Log.d('updatePartyLocation success');
    } catch (e, st) {
      Log.e('❌ [PartyRepo] updatePartyLocation Error', e, st);
      rethrow;
    }
  }

  /// Creates a new event for a party.
  Future<Event> createEvent(Event event) async {
    Log.d('createEvent called | partyId: ${event.partyId}');
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

      final result = Event.fromJson(data);
      Log.d('createEvent success | id: ${result.id}');
      return result;
    } catch (e, st) {
      Log.e('❌ [PartyRepo] createEvent Error', e, st);
      rethrow;
    }
  }

  /// Updates an existing event.
  Future<Event> updateEvent(Event event) async {
    Log.d('updateEvent called | id: ${event.id}');
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

      final result = Event.fromJson(data);
      Log.d('updateEvent success | id: ${result.id}');
      return result;
    } catch (e, st) {
      Log.e('❌ [PartyRepo] updateEvent Error', e, st);
      rethrow;
    }
  }

  /// Updates only the status of an event.
  Future<void> updateEventStatus(String eventId, String status) async {
    Log.d('updateEventStatus called | eventId: $eventId, status: $status');
    try {
      await _supabase
          .from('events')
          .update({'status': status})
          .eq('id', eventId);
      Log.d('updateEventStatus success');
    } catch (e, st) {
      Log.e('❌ [PartyRepo] updateEventStatus Error', e, st);
      rethrow;
    }
  }
}
