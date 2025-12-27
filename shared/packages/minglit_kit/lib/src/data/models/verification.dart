import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'verification.freezed.dart';
part 'verification.g.dart';

enum VerificationCategory {
  career,
  asset,
  marriage,
  academic,
  vehicle,
  etc;
}

enum VerificationStatus {
  pending,
  approved,
  rejected,
  @JsonValue('needs_correction')
  needsCorrection,
  resubmitted;
}

@freezed
abstract class VerificationRequirementStatus with _$VerificationRequirementStatus {
  const factory VerificationRequirementStatus({
    required Map<String, dynamic> master,
    Map<String, dynamic>? originalData,
    Map<String, dynamic>? activeRequest,
    Map<String, dynamic>? verifiedResult,
  }) = _VerificationRequirementStatus;

  factory VerificationRequirementStatus.fromJson(Map<String, dynamic> json) => _$VerificationRequirementStatusFromJson(json);

  const VerificationRequirementStatus._();

  bool get isApproved => verifiedResult != null;
  bool get hasActiveRequest => activeRequest != null;
  
  VerificationStatus? get status {
    if (activeRequest == null) return null;
    final statusStr = activeRequest!['status'] as String;
    return VerificationStatus.values.firstWhere(
      (e) => e.name == statusStr || (e == VerificationStatus.needsCorrection && statusStr == 'needs_correction'),
      orElse: () => VerificationStatus.pending,
    );
  }
}
