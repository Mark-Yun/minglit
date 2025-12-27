import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/src/data/models/verification.dart';

part 'verification_event.freezed.dart';

@freezed
class VerificationEvent with _$VerificationEvent {
  // User Events
  const factory VerificationEvent.loadPartnerRequirements({
    required String partnerId,
    required List<String> requiredIds,
  }) = _LoadPartnerRequirements;

  const factory VerificationEvent.submitVerification({
    required String partnerId,
    required String verificationId,
    required Map<String, dynamic> claimData,
    required List<XFile> proofFiles,
    String? existingRequestId,
  }) = _SubmitVerification;

  // Partner Events
  const factory VerificationEvent.loadPendingRequests() = _LoadPendingRequests;

  const factory VerificationEvent.reviewRequest({
    required String requestId,
    required VerificationStatus status,
    String? rejectionReason,
    String? comment,
  }) = _ReviewRequest;
}
