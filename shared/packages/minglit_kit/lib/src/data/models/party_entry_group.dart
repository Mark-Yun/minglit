import 'package:freezed_annotation/freezed_annotation.dart';

part 'party_entry_group.freezed.dart';
part 'party_entry_group.g.dart';

/// **Entry Group Template** (For Parties)
@freezed
abstract class EntryGroupTemplate with _$EntryGroupTemplate {
  const factory EntryGroupTemplate({
    required String id,
    @JsonKey(name: 'party_id') required String partyId,
    String? label,
    String? gender,
    @JsonKey(name: 'birth_year_min') int? birthYearMin,
    @JsonKey(name: 'birth_year_max') int? birthYearMax,
    @JsonKey(name: 'required_verification_ids')
    @Default([])
    List<String> requiredVerificationIds,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _EntryGroupTemplate;

  factory EntryGroupTemplate.fromJson(Map<String, dynamic> json) =>
      _$EntryGroupTemplateFromJson(json);
}

extension EntryGroupTemplateDbX on EntryGroupTemplate {
  Map<String, dynamic> toDbJson() {
    return toJson()
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');
  }
}

/// **Entry Group Instance** (For Events)
@freezed
abstract class EntryGroup with _$EntryGroup {
  const factory EntryGroup({
    required String id,
    @JsonKey(name: 'event_id') required String eventId,
    String? label,
    String? gender,
    @JsonKey(name: 'birth_year_min') int? birthYearMin,
    @JsonKey(name: 'birth_year_max') int? birthYearMax,
    @JsonKey(name: 'required_verification_ids')
    @Default([])
    List<String> requiredVerificationIds,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _EntryGroup;

  factory EntryGroup.fromJson(Map<String, dynamic> json) =>
      _$EntryGroupFromJson(json);

  /// Creates a fresh EntryGroup instance from a Template.
  factory EntryGroup.createFromTemplate(
    EntryGroupTemplate template, {
    String eventId = '',
  }) {
    final now = DateTime.now();
    return EntryGroup(
      id: '',
      eventId: eventId,
      label: template.label,
      gender: template.gender,
      birthYearMin: template.birthYearMin,
      birthYearMax: template.birthYearMax,
      requiredVerificationIds: template.requiredVerificationIds,
      createdAt: now,
      updatedAt: now,
    );
  }
}

extension EntryGroupX on EntryGroup {
  EntryGroupTemplate toTemplate() {
    return EntryGroupTemplate(
      id: id,
      partyId: '', // Not relevant for display
      label: label,
      gender: gender,
      birthYearMin: birthYearMin,
      birthYearMax: birthYearMax,
      requiredVerificationIds: requiredVerificationIds,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension EntryGroupDbX on EntryGroup {
  Map<String, dynamic> toDbJson({String? eventId}) {
    final json = toJson()
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');

    if (eventId != null) {
      json['event_id'] = eventId;
    }
    return json;
  }
}

/// Legacy compatibility (Optional, can be removed after full refactor)
typedef PartyEntryGroup = EntryGroupTemplate;
