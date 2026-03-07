import 'package:freezed_annotation/freezed_annotation.dart';

part 'partner_application.freezed.dart';
part 'partner_application.g.dart';

/// Data model for a Partner Application submission.
@freezed
abstract class PartnerApplication with _$PartnerApplication {
  /// Creates a [PartnerApplication] instance.
  const factory PartnerApplication({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @Default('draft') String status,
    @JsonKey(name: 'contact_phone') String? contactPhone,
    @JsonKey(name: 'contact_email') String? contactEmail,
    @JsonKey(name: 'brand_name') String? brandName,
    String? introduction,
    String? address,
    @JsonKey(name: 'biz_type') String? bizType,
    @JsonKey(name: 'biz_name') String? bizName,
    @JsonKey(name: 'biz_number') String? bizNumber,
    @JsonKey(name: 'representative_name') String? representativeName,
    @JsonKey(name: 'bank_name') String? bankName,
    @JsonKey(name: 'account_number') String? accountNumber,
    @JsonKey(name: 'account_holder') String? accountHolder,
    @JsonKey(name: 'biz_registration_path') String? bizRegistrationPath,
    @JsonKey(name: 'bankbook_path') String? bankbookPath,
    @JsonKey(name: 'tax_email') String? taxEmail,
    @JsonKey(name: 'profile_image_path') String? profileImagePath,
    @JsonKey(name: 'current_step') @Default(0) int currentStep,
    @JsonKey(name: 'admin_comment') String? adminComment,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _PartnerApplication;

  /// Creates a [PartnerApplication] from a JSON map.
  factory PartnerApplication.fromJson(Map<String, dynamic> json) =>
      _$PartnerApplicationFromJson(json);
}

/// Database-specific helpers for [PartnerApplication].
extension PartnerApplicationDbX on PartnerApplication {
  /// Returns JSON suitable for database inserts or updates.
  /// Excludes server-managed fields (id, user_id, created_at, updated_at).
  Map<String, dynamic> toDbJson() {
    return toJson()
      ..remove('id')
      ..remove('user_id')
      ..remove('created_at')
      ..remove('updated_at');
  }

}
