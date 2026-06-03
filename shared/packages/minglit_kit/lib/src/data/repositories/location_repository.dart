import 'package:minglit_kit/src/data/models/party.dart' show Location;
import 'package:minglit_kit/src/logic/providers/supabase_provider.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'location_repository.g.dart';

/// Provides the [LocationRepository].
@Riverpod(keepAlive: true)
LocationRepository locationRepository(Ref ref) {
  return LocationRepository(supabase: ref.watch(supabaseClientProvider));
}

/// Repository for location records and metadata.
class LocationRepository {
  /// Creates a [LocationRepository] with a Supabase client.
  LocationRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Fetches a single location by ID.
  Future<Location?> getLocationById(String id) async {
    Log.d('getLocationById called | id: $id');
    try {
      final data = await _supabase
          .from('locations_view')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (data == null) {
        Log.d('getLocationById success | result: null');
        return null;
      }
      final result = Location.fromJson(data);
      Log.d('getLocationById success | name: ${result.name}');
      return result;
    } catch (e, st) {
      Log.e('❌ [LocationRepo] getLocationById Error', e, st);
      rethrow;
    }
  }

  /// Fetches locations belonging to a specific partner.
  Future<List<Location>> getLocations(String partnerId) async {
    Log.d('getLocations called | partnerId: $partnerId');
    try {
      final data = await _supabase
          .from('locations_view')
          .select()
          .eq('partner_id', partnerId)
          .order('name', ascending: true);

      final result = (data as List<dynamic>)
          .map((json) => Location.fromJson(json as Map<String, dynamic>))
          .toList();

      Log.d('getLocations success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [LocationRepo] getLocations Error', e, st);
      rethrow;
    }
  }

  // Fix #316: createLocation via EF (partner-manage-party create action)
  /// Creates a new location entry via Edge Function.
  ///
  /// Note: Location creation is handled atomically within the
  /// partner-manage-party EF create action. This method is kept for
  /// standalone location creation when not part of a party creation flow.
  Future<Location> createLocation(Location location) async {
    Log.d('createLocation called | name: ${location.name}');
    try {
      // Use WKT (Well-Known Text) format for PostGIS geography type.
      // Format: POINT(longitude latitude)
      final point = 'POINT(${location.longitude} ${location.latitude})';

      final response = await _supabase.functions.invoke(
        'partner-manage-party',
        body: {
          'action': 'create_location',
          'partner_id': location.partnerId,
          'location': {
            'name': location.name,
            'address': location.address,
            'address_detail': location.addressDetail,
            'region_1': location.region1,
            'region_2': location.region2,
            'region_3': location.region3,
            'directions_guide': location.directionsGuide,
            'postal_code': location.postalCode,
            'geo_point': point,
          },
        },
      );
      if (response.status != 200) {
        final error = response.data is Map
            ? (response.data as Map)['error'] ?? 'Failed to create location'
            : 'Failed to create location';
        throw Exception(error);
      }

      final data = response.data as Map<String, dynamic>;
      final locationId = data['location_id'] as String;
      final result = await getLocationById(locationId);
      if (result == null) throw Exception('Created location not found');
      Log.d('createLocation success | id: ${result.id}');
      return result;
    } catch (e, st) {
      Log.e('❌ [LocationRepo] createLocation Error', e, st);
      rethrow;
    }
  }

  /// Updates location details (address detail and directions guide).
  ///
  /// Note: Location update is also available via partner-manage-party EF
  /// update action. This direct method is kept for cases where only
  /// location details need updating without party context.
  Future<void> updateLocationDetails({
    required String locationId,
    String? addressDetail,
    String? directionsGuide,
  }) async {
    Log.d('updateLocationDetails called | locationId: $locationId');
    try {
      final response = await _supabase.functions.invoke(
        'partner-manage-party',
        body: {
          'action': 'update_location',
          'location_id': locationId,
          'location': {
            'address_detail': addressDetail,
            'directions_guide': directionsGuide,
          },
        },
      );
      if (response.status != 200) {
        final error = response.data is Map
            ? (response.data as Map)['error'] ?? 'Failed to update location'
            : 'Failed to update location';
        throw Exception(error);
      }
      Log.d('updateLocationDetails success');
    } catch (e, st) {
      Log.e('❌ [LocationRepo] updateLocationDetails Error', e, st);
      rethrow;
    }
  }
}
