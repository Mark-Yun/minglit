// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_consent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserConsent _$UserConsentFromJson(Map<String, dynamic> json) => _UserConsent(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  consentKey: $enumDecode(_$ConsentTypeEnumMap, json['consent_key']),
  consented: json['consented'] as bool,
  policyVersion: (json['policy_version'] as num?)?.toInt(),
  consentedAt: DateTime.parse(json['consented_at'] as String),
  withdrawnAt: json['withdrawn_at'] == null
      ? null
      : DateTime.parse(json['withdrawn_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$UserConsentToJson(_UserConsent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'consent_key': _$ConsentTypeEnumMap[instance.consentKey]!,
      'consented': instance.consented,
      'policy_version': instance.policyVersion,
      'consented_at': instance.consentedAt.toIso8601String(),
      'withdrawn_at': instance.withdrawnAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$ConsentTypeEnumMap = {
  ConsentType.termsOfService: 'terms_of_service',
  ConsentType.privacyCollection: 'privacy_collection',
  ConsentType.ageConfirmation: 'age_confirmation',
  ConsentType.thirdPartyProvision: 'third_party_provision',
  ConsentType.marketingConsent: 'marketing_consent',
  ConsentType.identityVerification: 'identity_verification',
};

_ConsentInput _$ConsentInputFromJson(Map<String, dynamic> json) =>
    _ConsentInput(
      consentKey: $enumDecode(_$ConsentTypeEnumMap, json['consent_key']),
      consented: json['consented'] as bool,
      policyVersion: (json['policy_version'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ConsentInputToJson(_ConsentInput instance) =>
    <String, dynamic>{
      'consent_key': _$ConsentTypeEnumMap[instance.consentKey]!,
      'consented': instance.consented,
      'policy_version': instance.policyVersion,
    };
