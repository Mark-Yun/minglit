import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/partner_repository.dart';
import 'partner_event.dart';
import 'partner_state.dart';

class PartnerBloc extends Bloc<PartnerEvent, PartnerState> {
  final PartnerRepository _partnerRepository;

  PartnerBloc({required PartnerRepository partnerRepository})
      : _partnerRepository = partnerRepository,
        super(const PartnerState.initial()) {
    on<PartnerEvent>((event, emit) async {
      await event.when(
        checkApplicationStatus: () => _onCheckApplicationStatus(emit),
        submitApplication: (data, bizReg, bankbook) => _onSubmitApplication(data, bizReg, bankbook, emit),
        loadMembers: (partnerId) => _onLoadMembers(partnerId, emit),
      );
    });
  }

  Future<void> _onCheckApplicationStatus(Emitter<PartnerState> emit) async {
    emit(const PartnerState.loading());
    try {
      final application = await _partnerRepository.getMyApplication();
      emit(PartnerState.applicationLoaded(application));
    } catch (e) {
      emit(PartnerState.failure(e.toString()));
    }
  }

  Future<void> _onSubmitApplication(
    Map<String, dynamic> data,
    dynamic bizRegistrationFile, // Using dynamic to avoid explicit XFile if needed, but XFile is fine
    dynamic bankbookFile,
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
    } catch (e) {
      emit(PartnerState.failure(e.toString()));
    }
  }

  Future<void> _onLoadMembers(String partnerId, Emitter<PartnerState> emit) async {
    emit(const PartnerState.loading());
    try {
      final members = await _partnerRepository.getPartnerMembers(partnerId);
      emit(PartnerState.membersLoaded(members));
    } catch (e) {
      emit(PartnerState.failure(e.toString()));
    }
  }
}