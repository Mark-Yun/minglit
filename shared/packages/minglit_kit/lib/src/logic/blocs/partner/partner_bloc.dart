import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/src/core/error/error_handler.dart';
import 'package:minglit_kit/src/data/repositories/partner_repository.dart';
import 'package:minglit_kit/src/logic/blocs/partner/partner_event.dart';
import 'package:minglit_kit/src/logic/blocs/partner/partner_state.dart';

class PartnerBloc extends Bloc<PartnerEvent, PartnerState> {
  PartnerBloc({required PartnerRepository partnerRepository})
    : _partnerRepository = partnerRepository,
      super(const PartnerState.initial()) {
    on<PartnerEvent>((event, emit) async {
      await event.when(
        checkApplicationStatus: () => _onCheckApplicationStatus(emit),
        submitApplication:
            (data, bizReg, bankbook) =>
                _onSubmitApplication(data, bizReg, bankbook, emit),
        loadMembers: (partnerId) => _onLoadMembers(partnerId, emit),
        loadAllApplications:
            (status, term) => _onLoadAllApplications(status, term, emit),
        reviewApplication:
            (id, status, comment) =>
                _onReviewApplication(id, status, comment, emit),
      );
    });
  }
  final PartnerRepository _partnerRepository;

  Future<void> _onLoadAllApplications(
    String status,
    String? searchTerm,
    Emitter<PartnerState> emit,
  ) async {
    emit(const PartnerState.loading());
    try {
      final applications = await _partnerRepository.getAllApplications(
        status: status,
        searchTerm: searchTerm,
      );
      emit(PartnerState.applicationsLoaded(applications));
    } on Exception catch (e) {
      emit(PartnerState.failure(ErrorHandler.handle(e)));
    }
  }

  Future<void> _onReviewApplication(
    String applicationId,
    String status,
    String? adminComment,
    Emitter<PartnerState> emit,
  ) async {
    emit(const PartnerState.loading());
    try {
      await _partnerRepository.reviewApplication(
        applicationId: applicationId,
        status: status,
        adminComment: adminComment,
      );
      emit(const PartnerState.success());
      // Reload the list after review to update UI
      add(const PartnerEvent.loadAllApplications());
    } on Exception catch (e) {
      emit(PartnerState.failure(ErrorHandler.handle(e)));
    }
  }

  Future<void> _onCheckApplicationStatus(Emitter<PartnerState> emit) async {
    emit(const PartnerState.loading());
    try {
      final application = await _partnerRepository.getMyApplication();
      emit(PartnerState.applicationLoaded(application));
    } on Exception catch (e) {
      emit(PartnerState.failure(ErrorHandler.handle(e)));
    }
  }

  Future<void> _onSubmitApplication(
    Map<String, dynamic> data,
    XFile bizRegistrationFile,
    XFile bankbookFile,
    Emitter<PartnerState> emit,
  ) async {
    emit(const PartnerState.loading());
    try {
      await _partnerRepository.submitApplication(
        applicationData: data,
        bizRegistrationFile: bizRegistrationFile,
        bankbookFile: bankbookFile,
      );
      emit(const PartnerState.success());
      add(const PartnerEvent.checkApplicationStatus());
    } on Exception catch (e) {
      emit(PartnerState.failure(ErrorHandler.handle(e)));
    }
  }

  Future<void> _onLoadMembers(
    String partnerId,
    Emitter<PartnerState> emit,
  ) async {
    emit(const PartnerState.loading());
    try {
      final members = await _partnerRepository.getPartnerMembers(partnerId);
      emit(PartnerState.membersLoaded(members));
    } on Exception catch (e) {
      emit(PartnerState.failure(ErrorHandler.handle(e)));
    }
  }
}
