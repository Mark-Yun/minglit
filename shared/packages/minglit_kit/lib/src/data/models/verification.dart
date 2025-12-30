import 'package:freezed_annotation/freezed_annotation.dart';

part 'verification.freezed.dart';
part 'verification.g.dart';

/// Categories for different types of verification.
enum VerificationCategory {
  career,
  asset,
  marriage,
  academic,
  vehicle,
  etc,
}

/// Status of a verification request.
enum VerificationStatus {
  pending,
  approved,
  rejected,
  @JsonValue('needs_correction')
  needsCorrection,
  cancelled,
}

/// Represents a single field definition in the dynamic form schema.
@freezed
abstract class VerificationFormField with _$VerificationFormField {
  const factory VerificationFormField({
    /// Unique key for the field (e.g., 'company_name').
    required String key,

    /// Input type: 'text', 'number', 'file', 'date', etc.
    required String type,

    /// UI Label (e.g., '회사명').
    required String label,

    /// Whether this field is mandatory.
    @Default(true) bool required,

    /// Placeholder text for the input.
    String? placeholder,

    /// List of options (for select/radio types).
    List<String>? options,
  }) = _VerificationFormField;

  factory VerificationFormField.fromJson(Map<String, dynamic> json) =>
      _$VerificationFormFieldFromJson(json);
}

/// The main Verification definition model.
@freezed
abstract class Verification with _$Verification {
  const factory Verification({
    required String id,
    required VerificationCategory category,

    /// Internal identifier (e.g., 'global_career').
    @JsonKey(name: 'internal_name') required String internalName,

    /// Display name shown to users (e.g., '직장 인증').
    @JsonKey(name: 'display_name') required String displayName,

    /// Partner ID who owns this verification. Null means Global/System verification.
    @JsonKey(name: 'partner_id') String? partnerId,
    String? description,

    /// Icon identifier (e.g., 'briefcase').
    @JsonKey(name: 'icon_key') String? iconKey,

    /// Dynamic form definition.
    @JsonKey(name: 'form_schema')
    @Default([])
    List<VerificationFormField> formSchema,

    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Verification;

  factory Verification.fromJson(Map<String, dynamic> json) =>
      _$VerificationFromJson(json);
}

/// Helper model for wrapping verification status (UI helper).
@freezed
abstract class VerificationRequirementStatus
    with _$VerificationRequirementStatus {
  const factory VerificationRequirementStatus({
    required Verification master,

    /// User's original data (내 서랍 데이터)
    @JsonKey(name: 'user_verification') Map<String, dynamic>? userVerification,

    /// Active submission to a partner (제출 내역)
    @JsonKey(name: 'active_submission') Map<String, dynamic>? activeSubmission,

    /// Final verified result (출입증)
    @JsonKey(name: 'verified_result') Map<String, dynamic>? verifiedResult,
  }) = _VerificationRequirementStatus;

  const VerificationRequirementStatus._();

  factory VerificationRequirementStatus.fromJson(Map<String, dynamic> json) =>
      _$VerificationRequirementStatusFromJson(json);

  bool get isApproved => verifiedResult != null;

  bool get hasActiveRequest => activeSubmission != null;

  VerificationStatus? get status {
    if (activeSubmission == null) return null;
    final statusStr = activeSubmission!['status'] as String;
    return VerificationStatus.values.firstWhere(
      (e) =>
          e.name == statusStr ||
          (e == VerificationStatus.needsCorrection &&
              statusStr == 'needs_correction'),
      orElse: () => VerificationStatus.pending,
    );
  }
}
