// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VerificationRequirementStatus _$VerificationRequirementStatusFromJson(
  Map<String, dynamic> json,
) => _VerificationRequirementStatus(
  master: json['master'] as Map<String, dynamic>,
  originalData: json['originalData'] as Map<String, dynamic>?,
  activeRequest: json['activeRequest'] as Map<String, dynamic>?,
  verifiedResult: json['verifiedResult'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$VerificationRequirementStatusToJson(
  _VerificationRequirementStatus instance,
) => <String, dynamic>{
  'master': instance.master,
  'originalData': instance.originalData,
  'activeRequest': instance.activeRequest,
  'verifiedResult': instance.verifiedResult,
};
