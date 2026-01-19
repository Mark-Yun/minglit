import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:minglit_kit/src/data/models/partner.dart';
import 'package:minglit_kit/src/data/models/party_entry_group.dart';
import 'package:minglit_kit/src/data/models/ticket_template.dart';

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

extension LocationDbX on Location {
  Map<String, dynamic> toDbJson() {
    return toJson()
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');
  }
}

/// **Party Model**
///
/// Represents a party concept/template.
@freezed
abstract class Party with _$Party {
  const Party._();

  const factory Party({
    required String id,
    @JsonKey(name: 'partner_id') required String partnerId,
    required String title,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'location_id') String? locationId,
    @JsonKey(includeToJson: false) Location? location,
    Map<String, dynamic>? description, // Quill Delta JSON
    @JsonKey(name: 'image_urls') @Default([]) List<String> imageUrls,
    @JsonKey(name: 'contact_options')
    @Default({})
    Map<String, dynamic> contactOptions,
    @JsonKey(name: 'required_verification_ids')
    @Default([])
    List<String> requiredVerificationIds,
    @JsonKey(name: 'min_confirmed_count') @Default(0) int minConfirmedCount,
    @JsonKey(name: 'max_participants') @Default(20) int maxParticipants,
    @Default('active') String status,
    @JsonKey(includeToJson: false) List<TicketTemplate>? ticketTemplates,
    @JsonKey(includeToJson: false) Partner? partner,
    @JsonKey(includeToJson: false) List<EntryGroupTemplate>? entryGroups,
  }) = _Party;

  factory Party.fromJson(Map<String, dynamic> json) => _$PartyFromJson(json);

  String? get imageUrl => imageUrls.firstOrNull;
}

extension PartyX on Party {
  String get statusLabel {
    switch (status) {
      case 'active':
        return '운영중';
      case 'closed':
        return '종료됨';
      case 'draft':
        return '임시저장';
      default:
        return '알 수 없음';
    }
  }

  bool get isActive => status == 'active';
  bool get isClosed => status == 'closed';
  bool get isDraft => status == 'draft';

  List<String> get conditionSummaries {
    final groups = entryGroups ?? [];
    if (groups.isEmpty) return ['조건 없음'];

    return groups.map((group) {
      final gender = group.gender;
      final verifIds = group.requiredVerificationIds;

      var genderText = '성별 무관';
      if (gender == 'male') {
        genderText = '남성';
      } else if (gender == 'female') {
        genderText = '여성';
      }

      var birthYearText = '나이 무관';
      final min = group.birthYearMin;
      final max = group.birthYearMax;
      if (min != null && max != null) {
        birthYearText = '$min~$max년생';
      } else if (min != null) {
        birthYearText = '$min년생 이후';
      } else if (max != null) {
        birthYearText = '$max년생 이전';
      }

      String base;
      if (genderText == '성별 무관' && birthYearText == '나이 무관') {
        base = '조건 없음';
      } else if (birthYearText == '나이 무관') {
        base = genderText;
      } else if (genderText == '성별 무관') {
        base = birthYearText;
      } else {
        base = '$genderText ($birthYearText)';
      }

      // Handle label
      if (group.label != null && group.label!.isNotEmpty) {
        if (base == '조건 없음') {
          base = group.label!;
        } else {
          base = '${group.label} ($base)';
        }
      }

      // Add verification badge indicator
      if (verifIds.isNotEmpty) {
        return '$base +🛡️${verifIds.length}';
      }
      return base;
    }).toList();
  }
}

extension PartyDbX on Party {
  Map<String, dynamic> toDbJson() {
    return toJson()
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');
  }
}
