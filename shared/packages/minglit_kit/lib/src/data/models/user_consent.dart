import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_consent.freezed.dart';
part 'user_consent.g.dart';

/// Consent type identifiers matching DB consent_key values.
enum ConsentType {
  /// 서비스 이용약관 (필수)
  @JsonValue('terms_of_service')
  termsOfService,

  /// 개인정보 수집·이용 동의 (필수)
  @JsonValue('privacy_collection')
  privacyCollection,

  /// 만 14세 이상 확인 (필수)
  @JsonValue('age_confirmation')
  ageConfirmation,

  /// 제3자 제공 동의 (선택)
  @JsonValue('third_party_provision')
  thirdPartyProvision,

  /// 마케팅 정보 수신 동의 (선택)
  @JsonValue('marketing_consent')
  marketingConsent,

  /// 본인인증(CI/DI) 수집 동의
  @JsonValue('identity_verification')
  identityVerification;

  /// The required consent types for signup.
  static const requiredTypes = [
    ConsentType.termsOfService,
    ConsentType.privacyCollection,
    ConsentType.ageConfirmation,
  ];
}

/// A single user consent record from the `user_consents` table.
@freezed
abstract class UserConsent with _$UserConsent {
  /// Creates a [UserConsent] record.
  const factory UserConsent({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'consent_key') required ConsentType consentKey,
    required bool consented,
    @JsonKey(name: 'policy_version') int? policyVersion,
    @JsonKey(name: 'consented_at') required DateTime consentedAt,
    @JsonKey(name: 'withdrawn_at') DateTime? withdrawnAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _UserConsent;

  /// Creates a [UserConsent] from a JSON map.
  factory UserConsent.fromJson(Map<String, dynamic> json) =>
      _$UserConsentFromJson(json);
}

/// Input for saving a consent via the `save_user_consents` RPC.
@freezed
abstract class ConsentInput with _$ConsentInput {
  /// Creates a [ConsentInput].
  const factory ConsentInput({
    @JsonKey(name: 'consent_key') required ConsentType consentKey,
    required bool consented,
    @JsonKey(name: 'policy_version') int? policyVersion,
  }) = _ConsentInput;

  /// Creates a [ConsentInput] from a JSON map.
  factory ConsentInput.fromJson(Map<String, dynamic> json) =>
      _$ConsentInputFromJson(json);
}
