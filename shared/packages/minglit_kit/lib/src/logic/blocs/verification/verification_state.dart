import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:minglit_kit/minglit_kit.dart' show VerificationBloc;
import 'package:minglit_kit/src/data/models/verification.dart';
import 'package:minglit_kit/src/logic/blocs/verification/verification_bloc.dart'
    show VerificationBloc;

part 'verification_state.freezed.dart';

/// States for [VerificationBloc].
@freezed
class VerificationState with _$VerificationState {
  /// Initial state.
  const factory VerificationState.initial() = _Initial;

  /// Loading state.
  const factory VerificationState.loading() = _Loading;

  /// Verification requirements for a partner are loaded.
  const factory VerificationState.requirementsLoaded(
    List<VerificationRequirementStatus> requirements,
  ) = _RequirementsLoaded;

  /// Pending verification requests for a partner are loaded.
  const factory VerificationState.pendingRequestsLoaded(
    List<Map<String, dynamic>> requests,
  ) = _PendingRequestsLoaded;

  /// Generic success state.
  const factory VerificationState.success() = _Success;

  /// Operation failed.
  const factory VerificationState.failure(String message) = _Failure;
}
