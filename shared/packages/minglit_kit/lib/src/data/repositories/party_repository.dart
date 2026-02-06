import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/src/data/models/event.dart';
import 'package:minglit_kit/src/data/models/party.dart';
import 'package:minglit_kit/src/data/models/party_entry_group.dart';
import 'package:minglit_kit/src/data/models/ticket.dart';
import 'package:minglit_kit/src/data/models/ticket_template.dart';
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

  /// Uploads multiple party images and returns the list of public URLs.
  Future<List<String>> uploadPartyImages(
    List<XFile> files,
    String partnerId,
  ) async {
    Log.d(
      'uploadPartyImages called | partnerId: $partnerId, '
      'count: ${files.length}',
    );
    try {
      final urls = <String>[];
      for (final file in files) {
        // Reuse single upload logic or inline it
        // To keep it simple and parallel:
        final url = await uploadPartyImage(file, partnerId);
        urls.add(url);
      }
      Log.d('uploadPartyImages success | urls: $urls');
      return urls;
    } catch (e, st) {
      Log.e('❌ [PartyRepo] uploadPartyImages Error', e, st);
      rethrow;
    }
  }

  /// Uploads a party image and returns the public URL.
  Future<String> uploadPartyImage(XFile file, String partnerId) async {
    Log.d(
      'uploadPartyImage called | partnerId: $partnerId, '
      'file: ${file.name}',
    );
    try {
      final extension = p.extension(file.name);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // Structure: partner_id/timestamp_filename
      // Using a random part to avoid collision if multiple files have
      // same timestamp
      final random = DateTime.now().microsecond;
      final path = '$partnerId/${timestamp}_$random$extension';
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
      return url;
    } catch (e, st) {
      Log.e('❌ [PartyRepo] uploadPartyImage Error', e, st);
      rethrow;
    }
  }

  /// Creates a new party.
  Future<Party> createParty(
    Party party, {
    Map<String, dynamic>? extraFields,
  }) async {
    Log.d('createParty called | partnerId: ${party.partnerId}');
    try {
      final partyJson = party.toDbJson()..addAll(extraFields ?? {});

      final data = await _supabase
          .from('parties')
          .insert(partyJson)
          .select()
          .single();

      final createdParty = Party.fromJson(data);

      // Create associated ticket templates if provided
      final templates = party.ticketTemplates;
      if (templates != null && templates.isNotEmpty) {
        final templatesJson = templates
            .map((t) => t.copyWith(partyId: createdParty.id).toDbJson())
            .toList();
        await _supabase.from('ticket_templates').insert(templatesJson);
      }

      // Create associated entry groups if provided
      final entryGroups = party.entryGroups;
      if (entryGroups != null && entryGroups.isNotEmpty) {
        final groupsJson = entryGroups
            .map((g) => g.copyWith(partyId: createdParty.id).toDbJson())
            .toList();
        await _supabase.from('entry_groups').insert(groupsJson);
      }

      Log.d('createParty success | id: ${createdParty.id}');
      return createdParty;
    } catch (e, st) {
      Log.e('❌ [PartyRepo] createParty Error', e, st);
      rethrow;
    }
  }

  /// Retrieves a party by its ID.
  Future<Party?> getPartyById(String partyId) async {
    try {
      final data = await _supabase
          .from('parties')
          .select(
            '*, location:locations(*), '
            'ticket_templates(*), entry_group_templates(*)',
          )
          .eq('id', partyId)
          .maybeSingle();

      if (data == null) return null;

      return Party.fromJson(data);
    } catch (e, st) {
      Log.e('❌ [PartyRepo] getPartyById Error', e, st);
      rethrow;
    }
  }

  /// Updates an existing party.
  Future<Party> updateParty(Party party) async {
    Log.d('updateParty called | id: ${party.id}');
    try {
      final json = party.toDbJson();

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

  /// Retrieves all parties for a specific partner.
  Future<List<Party>> getPartiesByPartnerId(String partnerId) async {
    try {
      final data =
          await _supabase
                  .from('parties')
                  .select(
                    '*, location:locations(*), '
                    'ticket_templates(*), entry_group_templates(*)',
                  )
                  .eq('partner_id', partnerId)
                  .order('created_at', ascending: false)
              as List;
      return data.map((e) {
        return Party.fromJson(e as Map<String, dynamic>);
      }).toList();
    } catch (e, st) {
      Log.e('❌ [PartyRepo] getPartiesByPartnerId Error', e, st);
      rethrow;
    }
  }

  /// Retrieves all parties (e.g. for admin or dev list).
  Future<List<Party>> getParties() async {
    try {
      final data =
          await _supabase
                  .from('parties')
                  .select(
                    '*, location:locations(*), '
                    'ticket_templates(*), entry_group_templates(*)',
                  )
                  .order('created_at', ascending: false)
              as List;
      return data.map((e) {
        return Party.fromJson(e as Map<String, dynamic>);
      }).toList();
    } catch (e, st) {
      Log.e('❌ [PartyRepo] getParties Error', e, st);
      rethrow;
    }
  }

  /// Retrieves events for a specific party.
  Future<List<Event>> getEventsByPartyId(String partyId) async {
    try {
      final data =
          await _supabase
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

  /// Updates basic information of a party.
  Future<void> updatePartyBasicInfo({
    required String partyId,
    required String title,
    required Map<String, dynamic> description,
    List<String>? imageUrls,
    String? status,
  }) async {
    Log.d('updatePartyBasicInfo called | partyId: $partyId, title: $title');
    try {
      final updates = {
        'title': title,
        'description': description,
        'image_urls': imageUrls,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status != null) {
        updates['status'] = status;
      }

      await _supabase.from('parties').update(updates).eq('id', partyId);
      Log.d('updatePartyBasicInfo success');
    } catch (e, st) {
      Log.e('❌ [PartyRepo] updatePartyBasicInfo Error', e, st);
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
      final eventJson = event.toDbJson();

      final data = await _supabase
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
        await _supabase.from('entry_groups').insert(groupsJson);
      }

      // Create associated tickets if provided
      final eventTickets = event.tickets;
      if (eventTickets != null && eventTickets.isNotEmpty) {
        final ticketsJson = eventTickets
            .map((t) => t.toDbJson(eventId: createdEvent.id))
            .toList();

        await _supabase.from('tickets').insert(ticketsJson);
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

  /// Replaces all entry group templates for a party.
  Future<void> replaceEntryGroupTemplates(
    String partyId,
    List<EntryGroupTemplate> templates,
  ) async {
    Log.d(
      'replaceEntryGroupTemplates called | partyId: $partyId, '
      'count: ${templates.length}',
    );
    try {
      await _supabase.from('entry_groups').delete().eq('party_id', partyId);

      if (templates.isEmpty) return;

      final groupsJson = templates
          .map(
            (group) => group.copyWith(partyId: partyId).toJson()
              ..remove('created_at')
              ..remove('updated_at'),
          )
          .toList();

      await _supabase.from('entry_groups').insert(groupsJson);
      Log.d('replaceEntryGroupTemplates success');
    } catch (e, st) {
      Log.e('❌ [PartyRepo] replaceEntryGroupTemplates Error', e, st);
      rethrow;
    }
  }
}
