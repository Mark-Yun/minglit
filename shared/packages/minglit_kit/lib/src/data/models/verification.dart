import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:minglit_kit/src/data/models/verification_submission.dart';

part 'verification.freezed.dart';
part 'verification.g.dart';

/// Categories for different types of verification.
enum VerificationCategory {
  /// Career-related verification.
  career,

  /// Asset-related verification.
  asset,

  /// Marriage-related verification.
  marriage,

  /// Academic background verification.
  academic,

  /// Vehicle ownership verification.
  vehicle,

  /// Miscellaneous or other verification.
  etc,
}

/// Status of a verification request.
enum VerificationStatus {
  /// Submission is pending review.
  pending,

  /// Submission was approved.
  approved,

  /// Submission was rejected.
  rejected,

  /// Submission requires user corrections.
  @JsonValue('needs_correction')
  needsCorrection,

  /// Submission was cancelled.
  cancelled,
}

/// Represents a single field definition in the dynamic form schema.
@freezed
abstract class VerificationFormField with _$VerificationFormField {
  /// Creates a [VerificationFormField] definition.
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

  /// Creates a [VerificationFormField] from a JSON map.
  factory VerificationFormField.fromJson(Map<String, dynamic> json) =>
      _$VerificationFormFieldFromJson(json);
}

/// The main Verification definition model.
@freezed
abstract class Verification with _$Verification {
  /// Creates a [Verification] definition and metadata.
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

  /// Creates a [Verification] from a JSON map.
  factory Verification.fromJson(Map<String, dynamic> json) =>
      _$VerificationFromJson(json);
}

/// Database-specific helpers for [Verification].
extension VerificationDbX on Verification {
  /// Returns JSON suitable for database inserts or updates.
  Map<String, dynamic> toDbJson() {
    return toJson()
      ..remove('id')
      ..remove('created_at');
  }
}

/// Helper model for wrapping verification status (UI helper).
@freezed
abstract class VerificationRequirementStatus
    with _$VerificationRequirementStatus {
  /// Creates a [VerificationRequirementStatus] wrapper.
  const factory VerificationRequirementStatus({
    required Verification master,

    /// User's original data (내 서랍 데이터)
    @JsonKey(name: 'user_verification') Map<String, dynamic>? userVerification,

    /// Active submission to a partner (제출 내역)
    @JsonKey(name: 'active_submission')
    VerificationSubmission? activeSubmission,

    /// Final verified result (출입증)
    @JsonKey(name: 'verified_result') Map<String, dynamic>? verifiedResult,
  }) = _VerificationRequirementStatus;

  const VerificationRequirementStatus._();

  /// Creates a [VerificationRequirementStatus] from a JSON map.
  factory VerificationRequirementStatus.fromJson(Map<String, dynamic> json) =>
      _$VerificationRequirementStatusFromJson(json);

  /// Whether the verification has been approved.
  bool get isApproved => verifiedResult != null;

  /// Whether there is an active submission.
  bool get hasActiveRequest => activeSubmission != null;

  /// Current status of the active submission.
  VerificationStatus? get status => activeSubmission?.status;
}
