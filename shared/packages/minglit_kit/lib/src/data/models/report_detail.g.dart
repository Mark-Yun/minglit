// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReportDetail _$ReportDetailFromJson(Map<String, dynamic> json) =>
    _ReportDetail(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      targetId: json['target_id'] as String,
      targetType: $enumDecode(_$SocialTargetTypeEnumMap, json['target_type']),
      reason: json['reason'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      description: json['description'] as String?,
    );

Map<String, dynamic> _$ReportDetailToJson(_ReportDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'target_id': instance.targetId,
      'target_type': _$SocialTargetTypeEnumMap[instance.targetType]!,
      'reason': instance.reason,
      'created_at': instance.createdAt.toIso8601String(),
      'description': instance.description,
    };

const _$SocialTargetTypeEnumMap = {
  SocialTargetType.party: 'party',
  SocialTargetType.partner: 'partner',
  SocialTargetType.review: 'review',
  SocialTargetType.comment: 'comment',
};
