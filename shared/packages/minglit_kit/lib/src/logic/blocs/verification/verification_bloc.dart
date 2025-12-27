import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/verification_repository.dart';
import 'verification_event.dart';
import 'verification_state.dart';

class VerificationBloc extends Bloc<VerificationEvent, VerificationState> {
  final VerificationRepository _verificationRepository;

  VerificationBloc({required VerificationRepository verificationRepository})
      : _verificationRepository = verificationRepository,
        super(const VerificationState.initial()) {
    on<VerificationEvent>((event, emit) async {
      await event.when(
        loadPartnerRequirements: (partnerId, requiredIds) => 
            _onLoadPartnerRequirements(partnerId, requiredIds, emit),
        submitVerification: (partnerId, verificationId, claimData, proofFiles, existingRequestId) =>
            _onSubmitVerification(partnerId, verificationId, claimData, proofFiles, existingRequestId, emit),
        loadPendingRequests: () => _onLoadPendingRequests(emit),
        reviewRequest: (requestId, status, rejectionReason, comment) =>
            _onReviewRequest(requestId, status, rejectionReason, comment, emit),
      );
    });
  }

  Future<void> _onLoadPartnerRequirements(
    String partnerId,
    List<String> requiredIds,
    Emitter<VerificationState> emit,
  ) async {
    emit(const VerificationState.loading());
    try {
      final requirements = await _verificationRepository.getPartnerRequirementsStatus(
        partnerId: partnerId,
        requiredVerificationIds: requiredIds,
      );
      emit(VerificationState.requirementsLoaded(requirements));
    } catch (e) {
      emit(VerificationState.failure(e.toString()));
    }
  }

  Future<void> _onSubmitVerification(
    String partnerId,
    String verificationId,
    Map<String, dynamic> claimData,
    List<dynamic> proofFiles,
    String? existingRequestId,
    Emitter<VerificationState> emit,
  ) async {
    emit(const VerificationState.loading());
    try {
      await _verificationRepository.submitOrUpdateVerification(
        partnerId: partnerId,
        verificationId: verificationId,
        claimData: claimData,
        proofFiles: proofFiles.cast(),
        existingRequestId: existingRequestId,
      );
      emit(const VerificationState.success());
    } catch (e) {
      emit(VerificationState.failure(e.toString()));
    }
  }

  Future<void> _onLoadPendingRequests(Emitter<VerificationState> emit) async {
    emit(const VerificationState.loading());
    try {
      final requests = await _verificationRepository.getPendingRequests();
      emit(VerificationState.pendingRequestsLoaded(requests));
    } catch (e) {
      emit(VerificationState.failure(e.toString()));
    }
  }

  Future<void> _onReviewRequest(
    String requestId,
    dynamic status,
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
    } catch (e) {
      emit(VerificationState.failure(e.toString()));
    }
  }
}