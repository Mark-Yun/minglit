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
    String? sido,
    String? sigungu,
    // GeoJSON Point or lat/lng handled manually if needed.
    @JsonKey(includeFromJson: false, includeToJson: false) dynamic geoPoint,
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
    Map<String, dynamic>? description, // Quill Delta JSON
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'contact_phone') String? contactPhone,
    @JsonKey(name: 'contact_email') String? contactEmail,
    @JsonKey(name: 'required_verification_ids')
    @Default([])
    List<String> requiredVerificationIds,
    @Default('active') String status,
  }) = _Party;

  factory Party.fromJson(Map<String, dynamic> json) => _$PartyFromJson(json);
}
