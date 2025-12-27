import 'package:freezed_annotation/freezed_annotation.dart';

part 'verification.freezed.dart';
part 'verification.g.dart';

/// Categories for different types of verification.
enum VerificationCategory {
  /// Career/Job related.
  career,

  /// Asset/Wealth related.
  asset,

  /// Marriage/Single status related.
  marriage,

  /// Academic/Degree related.
  academic,

  /// Vehicle/Car related.
  vehicle,

  /// Other types.
  etc,
}

/// Status of a verification request.
enum VerificationStatus {
  /// Waiting for review.
  pending,

  /// Approved by reviewer.
  approved,

  /// Rejected with reason.
  rejected,

  /// Needs more info or correction.
  @JsonValue('needs_correction')
  needsCorrection,

  /// Resubmitted by user.
  resubmitted,
}

/// Comprehensive status of a specific verification requirement.
@freezed
abstract class VerificationRequirementStatus
    with _$VerificationRequirementStatus {
  /// Creates a [VerificationRequirementStatus] instance.
  const factory VerificationRequirementStatus({
    required Map<String, dynamic> master,
    Map<String, dynamic>? originalData,
    Map<String, dynamic>? activeRequest,
    Map<String, dynamic>? verifiedResult,
  }) = _VerificationRequirementStatus;

  /// Private constructor for custom getters.
  const VerificationRequirementStatus._();

  /// Creates a [VerificationRequirementStatus] from a JSON map.
  factory VerificationRequirementStatus.fromJson(Map<String, dynamic> json) =>
      _$VerificationRequirementStatusFromJson(json);

  /// Returns true if the requirement is fully approved.
  bool get isApproved => verifiedResult != null;

  /// Returns true if there is an ongoing request.
  bool get hasActiveRequest => activeRequest != null;

  /// Returns the current status of the active request.
  VerificationStatus? get status {
    if (activeRequest == null) return null;
    final statusStr = activeRequest!['status'] as String;
    return VerificationStatus.values.firstWhere(
      (e) =>
          e.name == statusStr ||
          (e == VerificationStatus.needsCorrection &&
              statusStr == 'needs_correction'),
      orElse: () => VerificationStatus.pending,
    );
  }
}
