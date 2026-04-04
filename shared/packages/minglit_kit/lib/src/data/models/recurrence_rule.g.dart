// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurrence_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecurrenceRule _$RecurrenceRuleFromJson(Map<String, dynamic> json) =>
    _RecurrenceRule(
      id: json['id'] as String,
      partyId: json['party_id'] as String,
      pattern: $enumDecode(_$RecurrencePatternEnumMap, json['pattern']),
      daysOfWeek:
          (json['days_of_week'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      monthDay: (json['month_day'] as num?)?.toInt(),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      endDate: json['end_date'] as String?,
      status:
          $enumDecodeNullable(_$RecurrenceStatusEnumMap, json['status']) ??
          RecurrenceStatus.active,
      lastGeneratedDate: json['last_generated_date'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$RecurrenceRuleToJson(_RecurrenceRule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'party_id': instance.partyId,
      'pattern': _$RecurrencePatternEnumMap[instance.pattern]!,
      'days_of_week': instance.daysOfWeek,
      'month_day': instance.monthDay,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'end_date': instance.endDate,
      'status': _$RecurrenceStatusEnumMap[instance.status]!,
      'last_generated_date': instance.lastGeneratedDate,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$RecurrencePatternEnumMap = {
  RecurrencePattern.weekly: 'weekly',
  RecurrencePattern.biweekly: 'biweekly',
  RecurrencePattern.monthly: 'monthly',
};

const _$RecurrenceStatusEnumMap = {
  RecurrenceStatus.active: 'active',
  RecurrenceStatus.paused: 'paused',
  RecurrenceStatus.cancelled: 'cancelled',
};
