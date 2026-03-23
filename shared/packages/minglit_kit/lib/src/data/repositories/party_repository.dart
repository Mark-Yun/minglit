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

  // Fix #316: createParty via EF (partner-manage-party)
  /// Creates a new party via Edge Function for server-side permission check.
  Future<Party> createParty(
    Party party, {
    Map<String, dynamic>? extraFields,
  }) async {
    Log.d('createParty called | partnerId: ${party.partnerId}');
    try {
      final partyJson = party.toDbJson()..addAll(extraFields ?? {});
      // Remove partner_id — server injects it from JWT membership
      partyJson.remove('partner_id');
      // Remove location — handled separately
      partyJson.remove('location');
      partyJson.remove('location_id');

      final body = <String, dynamic>{
        'action': 'create',
        'partner_id': party.partnerId,
        'party': partyJson,
      };

      // Fix #316: Pass location data for new location creation via EF
      if (party.locationId != null) {
        body['location_id'] = party.locationId;
      } else if (party.location != null) {
        final loc = party.location!;
        body['location'] = {
          'name': loc.name,
          'address': loc.address,
          if (loc.addressDetail != null) 'address_detail': loc.addressDetail,
          if (loc.region1 != null) 'region_1': loc.region1,
          if (loc.region2 != null) 'region_2': loc.region2,
          if (loc.region3 != null) 'region_3': loc.region3,
          if (loc.directionsGuide != null)
            'directions_guide': loc.directionsGuide,
          if (loc.postalCode != null) 'postal_code': loc.postalCode,
        };
      }

      // Attach ticket templates
      final templates = party.ticketTemplates;
      if (templates != null && templates.isNotEmpty) {
        body['ticket_templates'] = templates
            .map((t) => t.toDbJson()..remove('party_id'))
            .toList();
      }

      // Attach entry group templates
      final entryGroups = party.entryGroups;
      if (entryGroups != null && entryGroups.isNotEmpty) {
        body['entry_group_templates'] = entryGroups
            .map(
              (g) => g.toJson()
                ..remove('id')
                ..remove('party_id')
                ..remove('created_at')
                ..remove('updated_at'),
            )
            .toList();
      }

      final response = await supabaseClient.functions.invoke(
        'partner-manage-party',
        body: body,
      );

      if (response.status != 200) {
        final error = response.data is Map
            ? (response.data as Map)['error'] ?? 'Unknown error'
            : 'Failed to create party';
        throw Exception(error);
      }

      final data = response.data as Map<String, dynamic>;
      final partyId = data['party_id'] as String;

      // Fetch the created party with relations
      final created = await getPartyById(partyId);
      Log.d('createParty success | id: $partyId');
      return created!;
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

  // Fix #316: updateParty via EF (partner-manage-party)
  /// Updates an existing party via Edge Function.
  Future<Party> updateParty(Party party) async {
    Log.d('updateParty called | id: ${party.id}');
    try {
      final partyJson = party.toDbJson();
      partyJson.remove('partner_id');
      partyJson.remove('location');
      partyJson.remove('location_id');

      final response = await supabaseClient.functions.invoke(
        'partner-manage-party',
        body: {
          'action': 'update',
          'party_id': party.id,
          'party': partyJson,
        },
      );

      if (response.status != 200) {
        final error = response.data is Map
            ? (response.data as Map)['error'] ?? 'Unknown error'
            : 'Failed to update party';
        throw Exception(error);
      }

      final result = await getPartyById(party.id);
      Log.d('updateParty success | id: ${result?.id}');
      return result!;
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

  // Fix #316: updatePartyBasicInfo via EF (partner-manage-party)
  /// Updates basic information of a party via Edge Function.
  Future<void> updatePartyBasicInfo({
    required String partyId,
    required String title,
    required Map<String, dynamic> description,
    List<String>? imageUrls,
    String? status,
  }) async {
    Log.d('updatePartyBasicInfo called | partyId: $partyId, title: $title');
    try {
      final partyUpdates = <String, dynamic>{
        'title': title,
        'description': description,
      };

      // Fix #316: only include imageUrls when provided to avoid null overwrite
      if (imageUrls != null) {
        partyUpdates['image_urls'] = imageUrls;
      }

      if (status != null) {
        partyUpdates['status'] = status;
      }

      final response = await supabaseClient.functions.invoke(
        'partner-manage-party',
        body: {
          'action': 'update',
          'party_id': partyId,
          'party': partyUpdates,
        },
      );

      if (response.status != 200) {
        final error = response.data is Map
            ? (response.data as Map)['error'] ?? 'Unknown error'
            : 'Failed to update party';
        throw Exception(error);
      }
      Log.d('updatePartyBasicInfo success');
    } catch (e, st) {
      Log.e('❌ [PartyRepo] updatePartyBasicInfo Error', e, st);
      rethrow;
    }
  }

  // Fix #316: updatePartyStatus via EF (partner-manage-party)
  /// Updates only the status of a party via Edge Function.
  Future<void> updatePartyStatus(String partyId, String status) async {
    Log.d('updatePartyStatus called | partyId: $partyId, status: $status');
    try {
      final response = await supabaseClient.functions.invoke(
        'partner-manage-party',
        body: {
          'action': 'update_status',
          'party_id': partyId,
          'status': status,
        },
      );

      if (response.status != 200) {
        final error = response.data is Map
            ? (response.data as Map)['error'] ?? 'Unknown error'
            : 'Failed to update party status';
        throw Exception(error);
      }
      Log.d('updatePartyStatus success');
    } catch (e, st) {
      Log.e('❌ [PartyRepo] updatePartyStatus Error', e, st);
      rethrow;
    }
  }

  // Fix #316: updatePartyMetadata via EF (partner-manage-party)
  /// Updates the metadata of a party via Edge Function.
  Future<void> updatePartyMetadata(
    String partyId,
    Map<String, dynamic> metadata,
  ) async {
    try {
      final response = await supabaseClient.functions.invoke(
        'partner-manage-party',
        body: {
          'action': 'update',
          'party_id': partyId,
          'party': {'balance_config': metadata},
        },
      );

      if (response.status != 200) {
        final error = response.data is Map
            ? (response.data as Map)['error'] ?? 'Unknown error'
            : 'Failed to update party metadata';
        throw Exception(error);
      }
      Log.d('updatePartyMetadata success');
    } catch (e, st) {
      Log.e('❌ [PartyRepo] updatePartyMetadata Error', e, st);
      rethrow;
    }
  }

  // Fix #316: updatePartyLocation via EF (partner-manage-party)
  /// Updates the location of a party via Edge Function.
  Future<void> updatePartyLocation(String partyId, String locationId) async {
    Log.d(
      'updatePartyLocation called | partyId: $partyId, locationId: $locationId',
    );
    try {
      final response = await supabaseClient.functions.invoke(
        'partner-manage-party',
        body: {
          'action': 'update',
          'party_id': partyId,
          'location_id': locationId,
        },
      );

      if (response.status != 200) {
        final error = response.data is Map
            ? (response.data as Map)['error'] ?? 'Unknown error'
            : 'Failed to update party location';
        throw Exception(error);
      }
      Log.d('updatePartyLocation success');
    } catch (e, st) {
      Log.e('❌ [PartyRepo] updatePartyLocation Error', e, st);
      rethrow;
    }
  }
}
