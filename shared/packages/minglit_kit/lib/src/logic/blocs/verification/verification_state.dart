import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../data/models/verification.dart';

part 'verification_state.freezed.dart';

@freezed
class VerificationState with _$VerificationState {
  const factory VerificationState.initial() = _Initial;
  const factory VerificationState.loading() = _Loading;
  
  // User State
  const factory VerificationState.requirementsLoaded(List<VerificationRequirementStatus> requirements) = _RequirementsLoaded;
  
  // Partner State
  const factory VerificationState.pendingRequestsLoaded(List<Map<String, dynamic>> requests) = _PendingRequestsLoaded;
  
  const factory VerificationState.success() = _Success;
  const factory VerificationState.failure(String message) = _Failure;
}
