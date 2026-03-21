// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matching.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MatchRule _$MatchRuleFromJson(Map<String, dynamic> json) => _MatchRule(
      id: json['id'] as String,
      eventId: json['event_id'] as String,
      sourceGroupId: json['source_group_id'] as String,
      targetGroupId: json['target_group_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$MatchRuleToJson(_MatchRule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'event_id': instance.eventId,
      'source_group_id': instance.sourceGroupId,
      'target_group_id': instance.targetGroupId,
      'created_at': instance.createdAt.toIso8601String(),
    };

_MatchVote _$MatchVoteFromJson(Map<String, dynamic> json) => _MatchVote(
      eventId: json['event_id'] as String,
      voterId: json['voter_id'] as String,
      candidateId: json['candidate_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$MatchVoteToJson(_MatchVote instance) =>
    <String, dynamic>{
      'event_id': instance.eventId,
      'voter_id': instance.voterId,
      'candidate_id': instance.candidateId,
      'created_at': instance.createdAt.toIso8601String(),
    };

_MatchPair _$MatchPairFromJson(Map<String, dynamic> json) => _MatchPair(
      matchId: json['match_id'] as String,
      eventId: json['event_id'] as String,
      partnerId: json['partner_id'] as String,
      matchedAt: DateTime.parse(json['matched_at'] as String),
    );

Map<String, dynamic> _$MatchPairToJson(_MatchPair instance) =>
    <String, dynamic>{
      'match_id': instance.matchId,
      'event_id': instance.eventId,
      'partner_id': instance.partnerId,
      'matched_at': instance.matchedAt.toIso8601String(),
    };
