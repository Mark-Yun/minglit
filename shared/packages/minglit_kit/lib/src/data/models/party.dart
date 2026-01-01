import 'package:freezed_annotation/freezed_annotation.dart';

part 'party.freezed.dart';
part 'party.g.dart';

/// **Location Model**
///
/// Represents a physical venue managed by a partner.
@freezed
abstract class Location with _$Location {
  const factory Location({
    required String id,
    @JsonKey(name: 'partner_id') required String partnerId,
    required String name,
    required String address,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'address_detail') String? addressDetail,
    @JsonKey(name: 'region_1') String? region1,
    @JsonKey(name: 'region_2') String? region2,
    @JsonKey(name: 'region_3') String? region3,
    @JsonKey(name: 'directions_guide') String? directionsGuide,
    @JsonKey(name: 'postal_code') String? postalCode,
    // GeoJSON Point or lat/lng handled manually if needed.
    @JsonKey(includeFromJson: false, includeToJson: false) dynamic geoPoint,
    // UI Convenience fields
    @JsonKey(name: 'lat') @Default(0.0) double latitude,
    @JsonKey(name: 'lng') @Default(0.0) double longitude,
  }) = _Location;

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);
}

/// **Party Model**
///
/// Represents a party concept/template.
@freezed
abstract class Party with _$Party {
  const factory Party({
    required String id,
    @JsonKey(name: 'partner_id') required String partnerId,
    required String title,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'location_id') String? locationId,
    @JsonKey(includeToJson: false) Location? location,
    Map<String, dynamic>? description, // Quill Delta JSON
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'contact_options')
    @Default({})
    Map<String, dynamic> contactOptions,
    @Default({}) Map<String, dynamic> conditions, // JSONB
    @JsonKey(name: 'required_verification_ids')
    @Default([])
    List<String> requiredVerificationIds,
    @JsonKey(name: 'min_confirmed_count') @Default(0) int minConfirmedCount,
    @JsonKey(name: 'max_participants') @Default(20) int maxParticipants,
    @Default('active') String status,
  }) = _Party;

  factory Party.fromJson(Map<String, dynamic> json) => _$PartyFromJson(json);
}
