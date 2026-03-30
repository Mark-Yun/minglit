import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:minglit_kit/src/data/models/verification.dart';

part 'verification_submission.freezed.dart';
part 'verification_submission.g.dart';

/// **Verification Submission Model**
///
/// Represents a snapshot of user data submitted for review.
@freezed
abstract class VerificationSubmission with _$VerificationSubmission {
  /// Creates a [VerificationSubmission] for review tracking.
  const factory VerificationSubmission({
    required String id,
    @JsonKey(name: 'partner_id') required String partnerId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'verification_id') required String verificationId,
    required VerificationStatus status,
    @JsonKey(name: 'snapshot_data') required List<dynamic> snapshotData,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'application_id') String? applicationId,
    @JsonKey(name: 'reviewed_at') DateTime? reviewedAt,
    @JsonKey(name: 'reviewed_by') String? reviewedBy,
  }) = _VerificationSubmission;

  /// Creates a [VerificationSubmission] from a JSON map.
  factory VerificationSubmission.fromJson(Map<String, dynamic> json) =>
      _$VerificationSubmissionFromJson(json);
}
