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
    @JsonKey(name: 'brand_name') required String brandName,
    required String introduction,
    required String address,
    @JsonKey(name: 'contact_phone') required String contactPhone,
    @JsonKey(name: 'contact_email') required String contactEmail,
    @JsonKey(name: 'biz_type') required String bizType,
    @JsonKey(name: 'biz_name') required String bizName,
    @JsonKey(name: 'biz_number') required String bizNumber,
    @JsonKey(name: 'representative_name') required String representativeName,
    @JsonKey(name: 'bank_name') required String bankName,
    @JsonKey(name: 'account_number') required String accountNumber,
    @JsonKey(name: 'account_holder') required String accountHolder,
    @JsonKey(name: 'biz_registration_path') required String bizRegistrationPath,
    @JsonKey(name: 'bankbook_path') required String bankbookPath,
    @Default('pending') String status,
    @JsonKey(name: 'admin_comment') String? adminComment,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _PartnerApplication;

  /// Creates a [PartnerApplication] from a JSON map.
  factory PartnerApplication.fromJson(Map<String, dynamic> json) =>
      _$PartnerApplicationFromJson(json);
}
