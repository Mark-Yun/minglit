// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deletion_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeletionStatus _$DeletionStatusFromJson(Map<String, dynamic> json) =>
    _DeletionStatus(
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      gracePeriodEnds: json['grace_period_ends'] == null
          ? null
          : DateTime.parse(json['grace_period_ends'] as String),
      isPending: json['isPending'] as bool? ?? false,
    );

Map<String, dynamic> _$DeletionStatusToJson(_DeletionStatus instance) =>
    <String, dynamic>{
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'grace_period_ends': instance.gracePeriodEnds?.toIso8601String(),
      'isPending': instance.isPending,
    };
