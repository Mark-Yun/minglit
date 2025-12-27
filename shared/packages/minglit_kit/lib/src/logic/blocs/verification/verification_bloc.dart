import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/src/data/models/verification.dart';
import 'package:minglit_kit/src/data/repositories/verification_repository.dart';
import 'package:minglit_kit/src/logic/blocs/verification/verification_event.dart';
import 'package:minglit_kit/src/logic/blocs/verification/verification_state.dart';

class VerificationBloc extends Bloc<VerificationEvent, VerificationState> {
  VerificationBloc({required VerificationRepository verificationRepository})
    : _verificationRepository = verificationRepository,
      super(const VerificationState.initial()) {
    on<VerificationEvent>((event, emit) async {
      await event.when(
        loadPartnerRequirements:
            (partnerId, requiredIds) =>
                _onLoadPartnerRequirements(partnerId, requiredIds, emit),
        submitVerification:
            (
              partnerId,
              verificationId,
              claimData,
              proofFiles,
              existingRequestId,
            ) => _onSubmitVerification(
              partnerId,
              verificationId,
              claimData,
              proofFiles,
              existingRequestId,
              emit,
            ),
        loadPendingRequests: () => _onLoadPendingRequests(emit),
        reviewRequest:
            (requestId, status, rejectionReason, comment) => _onReviewRequest(
              requestId,
              status,
              rejectionReason,
              comment,
              emit,
            ),
      );
    });
  }
  final VerificationRepository _verificationRepository;

  Future<void> _onLoadPartnerRequirements(
    String partnerId,
    List<String> requiredIds,
    Emitter<VerificationState> emit,
  ) async {
    emit(const VerificationState.loading());
    try {
      final requirements = await _verificationRepository
          .getPartnerRequirementsStatus(
            partnerId: partnerId,
            requiredVerificationIds: requiredIds,
          );
      emit(VerificationState.requirementsLoaded(requirements));
    } on Exception catch (e) {
      emit(VerificationState.failure(e.toString()));
    }
  }

  Future<void> _onSubmitVerification(
    String partnerId,
    String verificationId,
    Map<String, dynamic> claimData,
    List<XFile> proofFiles,
    String? existingRequestId,
    Emitter<VerificationState> emit,
  ) async {
    emit(const VerificationState.loading());
    try {
      await _verificationRepository.submitOrUpdateVerification(
        partnerId: partnerId,
        verificationId: verificationId,
        claimData: claimData,
        proofFiles: proofFiles,
        existingRequestId: existingRequestId,
      );
      emit(const VerificationState.success());
    } on Exception catch (e) {
      emit(VerificationState.failure(e.toString()));
    }
  }

  Future<void> _onLoadPendingRequests(Emitter<VerificationState> emit) async {
    emit(const VerificationState.loading());
    try {
      final requests = await _verificationRepository.getPendingRequests();
      emit(VerificationState.pendingRequestsLoaded(requests));
    } on Exception catch (e) {
      emit(VerificationState.failure(e.toString()));
    }
  }

  Future<void> _onReviewRequest(
    String requestId,
    VerificationStatus status,
    String? rejectionReason,
    String? comment,
    Emitter<VerificationState> emit,
  ) async {
    emit(const VerificationState.loading());
    try {
      await _verificationRepository.reviewRequest(
        requestId: requestId,
        status: status,
        rejectionReason: rejectionReason,
      );

      if (comment != null && comment.isNotEmpty) {
        await _verificationRepository.submitComment(
          requestId: requestId,
          content: {'text': comment},
        );
      }

      emit(const VerificationState.success());
      add(const VerificationEvent.loadPendingRequests());
    } on Exception catch (e) {
      emit(VerificationState.failure(e.toString()));
    }
  }
}
