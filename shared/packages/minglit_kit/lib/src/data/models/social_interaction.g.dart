// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_interaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SocialInteraction _$SocialInteractionFromJson(Map<String, dynamic> json) =>
    _SocialInteraction(
      userId: json['userId'] as String,
      targetId: json['targetId'] as String,
      targetType: $enumDecode(_$SocialTargetTypeEnumMap, json['targetType']),
      interactionType: $enumDecode(
        _$SocialInteractionTypeEnumMap,
        json['interactionType'],
      ),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$SocialInteractionToJson(
  _SocialInteraction instance,
) =>
    <String, dynamic>{
      'userId': instance.userId,
      'targetId': instance.targetId,
      'targetType': _$SocialTargetTypeEnumMap[instance.targetType]!,
      'interactionType':
          _$SocialInteractionTypeEnumMap[instance.interactionType]!,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$SocialTargetTypeEnumMap = {
  SocialTargetType.party: 'party',
  SocialTargetType.partner: 'partner',
  SocialTargetType.review: 'review',
  SocialTargetType.comment: 'comment',
};

const _$SocialInteractionTypeEnumMap = {
  SocialInteractionType.like: 'like',
  SocialInteractionType.subscribe: 'subscribe',
  SocialInteractionType.bookmark: 'bookmark',
  SocialInteractionType.block: 'block',
  SocialInteractionType.report: 'report',
  SocialInteractionType.dislike: 'dislike',
};
