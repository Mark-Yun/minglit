import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:minglit_kit/src/data/models/partner.dart';
import 'package:minglit_kit/src/data/models/party_entry_group.dart';
import 'package:minglit_kit/src/data/models/tag.dart';
import 'package:minglit_kit/src/data/models/ticket_template.dart';

part 'party.freezed.dart';
part 'party.g.dart';

/// **Location Model**
///
/// Represents a physical venue managed by a partner.
@freezed
abstract class Location with _$Location {
  /// Creates a [Location] with address and coordinates.
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

  /// Creates a [Location] from a JSON map.
  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);
}

/// Database-specific helpers for [Location].
extension LocationDbX on Location {
  /// Returns JSON suitable for database inserts or updates.
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
  /// Creates a [Party] template with scheduling rules.
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
    @Default({}) Map<String, dynamic> metadata,
    @JsonKey(name: 'required_verification_ids')
    @Default([])
    List<String> requiredVerificationIds,
    @JsonKey(name: 'min_confirmed_count') @Default(0) int minConfirmedCount,
    @JsonKey(name: 'max_participants') @Default(20) int maxParticipants,
    @Default('active') String status,
    @Default('public') String visibility,
    @JsonKey(includeToJson: false) List<TicketTemplate>? ticketTemplates,
    @JsonKey(includeToJson: false) Partner? partner,
    @JsonKey(name: 'entry_group_templates', includeToJson: false)
    List<EntryGroupTemplate>? entryGroups,
    // Tag Discovery (#1094-1096)
    @JsonKey(includeToJson: false) List<Tag>? tags,
  }) = _Party;
  const Party._();

  /// Creates a [Party] from a JSON map.
  factory Party.fromJson(Map<String, dynamic> json) => _$PartyFromJson(json);

  /// Returns the first available image URL, if any.
  String? get imageUrl => imageUrls.firstOrNull;
}

/// Convenience helpers for [Party].
extension PartyX on Party {
  /// Returns the localized status label.
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

  /// Whether the party is active.
  bool get isActive => status == 'active';

  /// Whether the party is closed.
  bool get isClosed => status == 'closed';

  /// Whether the party is in draft state.
  bool get isDraft => status == 'draft';

  /// Whether the party is private (link-only access).
  bool get isPrivate => visibility == 'private';

  /// Whether the party is publicly visible.
  bool get isPublic => visibility == 'public';

  /// Summarizes entry conditions for display.
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
      final label = group.label;
      if (label != null && label.isNotEmpty) {
        if (base == '조건 없음') {
          base = label;
        } else {
          base = '$label ($base)';
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

/// Database-specific helpers for [Party].
extension PartyDbX on Party {
  /// Returns JSON suitable for database inserts or updates.
  Map<String, dynamic> toDbJson() {
    return toJson()
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');
  }
}
