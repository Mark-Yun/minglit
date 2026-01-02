// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'party_entry_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PartyEntryGroup _$PartyEntryGroupFromJson(Map<String, dynamic> json) =>
    _PartyEntryGroup(
      id: json['id'] as String,
      label: json['label'] as String?,
      gender: json['gender'] as String?,
      birthYearRange: json['birth_year_range'] as Map<String, dynamic>?,
      requiredVerificationIds:
          (json['required_verification_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$PartyEntryGroupToJson(_PartyEntryGroup instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'gender': instance.gender,
      'birth_year_range': instance.birthYearRange,
      'required_verification_ids': instance.requiredVerificationIds,
    };
