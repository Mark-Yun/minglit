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
part 'party_event_repository.dart';
part 'party_matching_repository.dart';

/// Provider for PartyRepository.
@Riverpod(keepAlive: true)
PartyRepository partyRepository(Ref ref) {
  return PartyRepository();
}

/// Repository for Party-related data operations.
///
/// Core party CRUD operations live here. Extended by:
/// - [_PartyEventRepository] — Event CRUD within a party.
/// - [_PartyMatchingRepository] — Entry group template management.
class PartyRepository extends _SupabasePartyContextBase
    with _PartyEventRepository, _PartyMatchingRepository {
  /// Creates a [PartyRepository] with a Supabase client.
  PartyRepository({SupabaseClient? supabase})
    : super(supabase ?? Supabase.instance.client);
}

abstract class _SupabasePartyContext {
  SupabaseClient get supabaseClient;
}

abstract class _SupabasePartyContextBase implements _SupabasePartyContext {
  const _SupabasePartyContextBase(this.supabaseClient);

  @override
  final SupabaseClient supabaseClient;

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

      await supabaseClient.storage
          .from('party-assets')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final url = supabaseClient.storage
          .from('party-assets')
          .getPublicUrl(path);
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

      final data = await supabaseClient
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
        await supabaseClient.from('ticket_templates').insert(templatesJson);
      }

      // Create associated entry groups if provided
      final entryGroups = party.entryGroups;
      if (entryGroups != null && entryGroups.isNotEmpty) {
        final groupsJson = entryGroups
            .map((g) => g.copyWith(partyId: createdParty.id).toDbJson())
            .toList();
        await supabaseClient.from('entry_groups').insert(groupsJson);
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
      final data = await supabaseClient
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

      final data = await supabaseClient
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
          await supabaseClient
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
          await supabaseClient
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

      await supabaseClient.from('parties').update(updates).eq('id', partyId);
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
      await supabaseClient
          .from('parties')
          .update({'status': status})
          .eq('id', partyId);
      Log.d('updatePartyStatus success');
    } catch (e, st) {
      Log.e('❌ [PartyRepo] updatePartyStatus Error', e, st);
      rethrow;
    }
  }

  /// Updates the metadata of a party.
  Future<void> updatePartyMetadata(
      String partyId, Map<String, dynamic> metadata) async {
    try {
      await supabaseClient
          .from('parties')
          .update({'metadata': metadata})
          .eq('id', partyId);
      Log.d('updatePartyMetadata success');
    } catch (e, st) {
      Log.e('❌ [PartyRepo] updatePartyMetadata Error', e, st);
      rethrow;
    }
  }

  /// Updates the location of a party.
  Future<void> updatePartyLocation(String partyId, String locationId) async {
    Log.d(
      'updatePartyLocation called | partyId: $partyId, locationId: $locationId',
    );
    try {
      await supabaseClient
          .from('parties')
          .update({'location_id': locationId})
          .eq('id', partyId);
      Log.d('updatePartyLocation success');
    } catch (e, st) {
      Log.e('❌ [PartyRepo] updatePartyLocation Error', e, st);
      rethrow;
    }
  }
}
