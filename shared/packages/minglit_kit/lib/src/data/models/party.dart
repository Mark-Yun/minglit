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
    @Default([]) List<dynamic> conditions, // JSONB Array of condition sets
    @JsonKey(name: 'required_verification_ids')
    @Default([])
    List<String> requiredVerificationIds,
    @JsonKey(name: 'min_confirmed_count') @Default(0) int minConfirmedCount,
    @JsonKey(name: 'max_participants') @Default(20) int maxParticipants,
    @Default('active') String status,
  }) = _Party;

  factory Party.fromJson(Map<String, dynamic> json) => _$PartyFromJson(json);
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
    if (conditions.isEmpty) return ['조건 없음'];

    final summaries = conditions.map((cond) {
      if (cond is! Map) return '';

      final gender = cond['gender'];
      final ageData = cond['age_range'];
      final verifIds = cond['required_verification_ids'] as List?;

      var genderText = '성별 무관';
      if (gender == 'male') {
        genderText = '남성';
      } else if (gender == 'female') {
        genderText = '여성';
      }

      var ageText = '나이 무관';
      if (ageData is Map) {
        final min = ageData['min'];
        final max = ageData['max'];
        if (min != null && max != null) {
          ageText = '$min~$max년생';
        } else if (min != null) {
          ageText = '$min년생 이후';
        } else if (max != null) {
          ageText = '$max년생 이전';
        }
      }

      String base;
      if (genderText == '성별 무관' && ageText == '나이 무관') {
        base = '전체';
      } else if (ageText == '나이 무관') {
        base = genderText;
      } else if (genderText == '성별 무관') {
        base = ageText;
      } else {
        base = '$genderText($ageText)';
      }

      // 인증 정보 추가
      if (verifIds != null && verifIds.isNotEmpty) {
        return '$base +🛡️${verifIds.length}';
      }
      return base;
    }).where((s) => s.isNotEmpty).toList();

    if (summaries.isEmpty) return ['조건 없음'];
    return summaries;
  }
}
