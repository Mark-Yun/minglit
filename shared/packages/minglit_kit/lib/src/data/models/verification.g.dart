// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VerificationFormField _$VerificationFormFieldFromJson(
  Map<String, dynamic> json,
) => _VerificationFormField(
  key: json['key'] as String,
  type: json['type'] as String,
  label: json['label'] as String,
  required: json['required'] as bool? ?? true,
  placeholder: json['placeholder'] as String?,
  options: (json['options'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$VerificationFormFieldToJson(
  _VerificationFormField instance,
) => <String, dynamic>{
  'key': instance.key,
  'type': instance.type,
  'label': instance.label,
  'required': instance.required,
  'placeholder': instance.placeholder,
  'options': instance.options,
};

_Verification _$VerificationFromJson(Map<String, dynamic> json) =>
    _Verification(
      id: json['id'] as String,
      category: $enumDecode(_$VerificationCategoryEnumMap, json['category']),
      internalName: json['internal_name'] as String,
      displayName: json['display_name'] as String,
      partnerId: json['partner_id'] as String?,
      description: json['description'] as String?,
      iconKey: json['icon_key'] as String?,
      formSchema:
          (json['form_schema'] as List<dynamic>?)
              ?.map(
                (e) =>
                    VerificationFormField.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$VerificationToJson(_Verification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': _$VerificationCategoryEnumMap[instance.category]!,
      'internal_name': instance.internalName,
      'display_name': instance.displayName,
      'partner_id': instance.partnerId,
      'description': instance.description,
      'icon_key': instance.iconKey,
      'form_schema': instance.formSchema,
      'is_active': instance.isActive,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$VerificationCategoryEnumMap = {
  VerificationCategory.career: 'career',
  VerificationCategory.asset: 'asset',
  VerificationCategory.marriage: 'marriage',
  VerificationCategory.academic: 'academic',
  VerificationCategory.vehicle: 'vehicle',
  VerificationCategory.etc: 'etc',
};

_VerificationRequirementStatus _$VerificationRequirementStatusFromJson(
  Map<String, dynamic> json,
) => _VerificationRequirementStatus(
  master: Verification.fromJson(json['master'] as Map<String, dynamic>),
  userVerification: json['user_verification'] as Map<String, dynamic>?,
  activeSubmission: json['active_submission'] as Map<String, dynamic>?,
  verifiedResult: json['verified_result'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$VerificationRequirementStatusToJson(
  _VerificationRequirementStatus instance,
) => <String, dynamic>{
  'master': instance.master,
  'user_verification': instance.userVerification,
  'active_submission': instance.activeSubmission,
  'verified_result': instance.verifiedResult,
};
