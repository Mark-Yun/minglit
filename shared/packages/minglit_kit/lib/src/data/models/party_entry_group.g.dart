// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'party_entry_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EntryGroupTemplate _$EntryGroupTemplateFromJson(Map<String, dynamic> json) =>
    _EntryGroupTemplate(
      id: json['id'] as String,
      partyId: json['party_id'] as String,
      label: json['label'] as String?,
      gender: json['gender'] as String?,
      birthYearMin: (json['birth_year_min'] as num?)?.toInt(),
      birthYearMax: (json['birth_year_max'] as num?)?.toInt(),
      requiredVerificationIds:
          (json['required_verification_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$EntryGroupTemplateToJson(_EntryGroupTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'party_id': instance.partyId,
      'label': instance.label,
      'gender': instance.gender,
      'birth_year_min': instance.birthYearMin,
      'birth_year_max': instance.birthYearMax,
      'required_verification_ids': instance.requiredVerificationIds,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };

_EntryGroup _$EntryGroupFromJson(Map<String, dynamic> json) => _EntryGroup(
  id: json['id'] as String,
  eventId: json['event_id'] as String,
  label: json['label'] as String?,
  gender: json['gender'] as String?,
  birthYearMin: (json['birth_year_min'] as num?)?.toInt(),
  birthYearMax: (json['birth_year_max'] as num?)?.toInt(),
  requiredVerificationIds:
      (json['required_verification_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$EntryGroupToJson(_EntryGroup instance) =>
    <String, dynamic>{
      'id': instance.id,
      'event_id': instance.eventId,
      'label': instance.label,
      'gender': instance.gender,
      'birth_year_min': instance.birthYearMin,
      'birth_year_max': instance.birthYearMax,
      'required_verification_ids': instance.requiredVerificationIds,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
