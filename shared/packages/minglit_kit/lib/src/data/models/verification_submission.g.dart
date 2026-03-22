// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_submission.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VerificationSubmission _$VerificationSubmissionFromJson(
  Map<String, dynamic> json,
) => _VerificationSubmission(
  id: json['id'] as String,
  partnerId: json['partner_id'] as String,
  userId: json['user_id'] as String,
  verificationId: json['verification_id'] as String,
  status: $enumDecode(_$VerificationStatusEnumMap, json['status']),
  snapshotData: json['snapshot_data'] as List<dynamic>,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  applicationId: json['application_id'] as String?,
  reviewedAt: json['reviewed_at'] == null
      ? null
      : DateTime.parse(json['reviewed_at'] as String),
  reviewedBy: json['reviewed_by'] as String?,
);

Map<String, dynamic> _$VerificationSubmissionToJson(
  _VerificationSubmission instance,
) => <String, dynamic>{
  'id': instance.id,
  'partner_id': instance.partnerId,
  'user_id': instance.userId,
  'verification_id': instance.verificationId,
  'status': _$VerificationStatusEnumMap[instance.status]!,
  'snapshot_data': instance.snapshotData,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'application_id': instance.applicationId,
  'reviewed_at': instance.reviewedAt?.toIso8601String(),
  'reviewed_by': instance.reviewedBy,
};

const _$VerificationStatusEnumMap = {
  VerificationStatus.pending: 'pending',
  VerificationStatus.approved: 'approved',
  VerificationStatus.rejected: 'rejected',
};
