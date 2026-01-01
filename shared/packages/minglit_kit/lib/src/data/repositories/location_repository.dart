import 'package:minglit_kit/src/data/models/party.dart' show Location;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'location_repository.g.dart';

@Riverpod(keepAlive: true)
LocationRepository locationRepository(Ref ref) {
  return LocationRepository();
}

class LocationRepository {
  LocationRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Fetches a single location by ID.
  Future<Location?> getLocationById(String id) async {
    final data = await _supabase
        .from('locations_view')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return Location.fromJson(data);
  }

  /// Fetches locations belonging to a specific partner.
  Future<List<Location>> getLocations(String partnerId) async {
    final data = await _supabase
        .from('locations_view')
        .select()
        .eq('partner_id', partnerId)
        .order('name', ascending: true);

    return (data as List<dynamic>)
        .map((json) => Location.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Creates a new location entry.
  Future<Location> createLocation(Location location) async {
    // Use WKT (Well-Known Text) format for PostGIS geography type.
    // Format: POINT(longitude latitude)
    final point = 'POINT(${location.longitude} ${location.latitude})';

    final data = await _supabase
        .from('locations')
        .insert({
          'partner_id': location.partnerId,
          'name': location.name,
          'address': location.address,
          'address_detail': location.addressDetail,
          'region_1': location.region1,
          'region_2': location.region2,
          'region_3': location.region3,
          'directions_guide': location.directionsGuide,
          'postal_code': location.postalCode,
          'geo_point': point,
        })
        .select()
        .single();

    // Merging input lat/lng into response data since insert().select()
    // returns table columns (geo_point WKB) not view columns (lat/lng).
    final mergedData = Map<String, dynamic>.from(data);
    mergedData['lat'] = location.latitude;
    mergedData['lng'] = location.longitude;

    return Location.fromJson(mergedData);
  }

  /// Updates location details (address detail and directions guide).
  Future<void> updateLocationDetails({
    required String locationId,
    String? addressDetail,
    String? directionsGuide,
  }) async {
    await _supabase.from('locations').update({
      'address_detail': addressDetail,
      'directions_guide': directionsGuide,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', locationId);
  }
}
