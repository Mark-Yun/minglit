part of 'partner_apply_controller.dart';

mixin _PartnerApplyDraft on _$PartnerApplyController {
  Future<void> loadDraft() async {
    final repo = ref.read(partnerRepositoryProvider);
    final application = await repo.getMyApplication();
    if (application == null) return;
    if (application.status != 'draft' &&
        application.status != 'needs_correction') {
      return;
    }

    state = state.copyWith(
      applicationId: application.id,
      currentStep: application.currentStep,
      brandName: application.brandName ?? '',
      introduction: application.introduction ?? '',
      profileImagePath: application.profileImagePath,
      bizType: application.bizType ?? 'individual',
      bizName: application.bizName ?? '',
      bizNumber: application.bizNumber ?? '',
      representativeName: application.representativeName ?? '',
      contactPhone: application.contactPhone ?? '',
      contactEmail: application.contactEmail ?? '',
      address: application.address ?? '',
      bankName: application.bankName ?? '',
      accountNumber: application.accountNumber ?? '',
      accountHolder: application.accountHolder ?? '',
      taxEmail: application.taxEmail ?? '',
      bizRegistrationPath: application.bizRegistrationPath,
      bankbookPath: application.bankbookPath,
    );
  }

  Future<void> saveDraft() async {
    state = state.copyWith(isSaving: true);
    try {
      final repo = ref.read(partnerRepositoryProvider);
      final application = PartnerApplication(
        id: state.applicationId ?? '',
        userId: '',
        brandName: state.brandName.isEmpty ? null : state.brandName,
        introduction: state.introduction.isEmpty ? null : state.introduction,
        profileImagePath: state.profileImagePath,
        bizType: state.bizType,
        bizName: state.bizName.isEmpty ? null : state.bizName,
        bizNumber: state.bizNumber.isEmpty ? null : state.bizNumber,
        representativeName: state.representativeName.isEmpty
            ? null
            : state.representativeName,
        contactPhone: state.contactPhone.isEmpty ? null : state.contactPhone,
        contactEmail: state.contactEmail.isEmpty ? null : state.contactEmail,
        address: state.address.isEmpty ? null : state.address,
        bankName: state.bankName.isEmpty ? null : state.bankName,
        accountNumber: state.accountNumber.isEmpty ? null : state.accountNumber,
        accountHolder: state.accountHolder.isEmpty ? null : state.accountHolder,
        taxEmail: state.taxEmail.isEmpty ? null : state.taxEmail,
        bizRegistrationPath: state.bizRegistrationPath,
        bankbookPath: state.bankbookPath,
        currentStep: state.currentStep,
      );
      final result = await repo.saveDraft(application);
      state = state.copyWith(applicationId: result.id, isSaving: false);
    } on Exception catch (e, st) {
      state = state.copyWith(isSaving: false);
      Log.e('saveDraft error', e, st);
    }
  }

  Future<void> uploadProfileImage(XFile file) async {
    try {
      final repo = ref.read(partnerRepositoryProvider);
      // Fix #382: 강제 언래핑 제거 — local variable로 null 안전성 확보
      final oldPath = state.profileImagePath;
      if (oldPath != null) {
        await repo.deleteUploadedFile(oldPath);
      }
      final path = await repo.uploadProfileImage(file);
      state = state.copyWith(profileImagePath: path, profileImageFile: file);
      await saveDraft();
    } on Exception catch (e, st) {
      Log.e('uploadProfileImage error', e, st);
    }
  }

  Future<void> uploadBizRegistration(XFile file) async {
    try {
      final repo = ref.read(partnerRepositoryProvider);
      // Fix #382: 강제 언래핑 제거 — local variable로 null 안전성 확보
      final oldBizPath = state.bizRegistrationPath;
      if (oldBizPath != null) {
        await repo.deleteUploadedFile(oldBizPath);
      }
      final path = await repo.uploadBizRegistration(file);
      state = state.copyWith(
        bizRegistrationPath: path,
        bizRegistrationFile: file,
      );
      await saveDraft();
    } on Exception catch (e, st) {
      Log.e('uploadBizRegistration error', e, st);
    }
  }

  Future<void> uploadBankbook(XFile file) async {
    try {
      final repo = ref.read(partnerRepositoryProvider);
      // Fix #382: 강제 언래핑 제거 — local variable로 null 안전성 확보
      final oldBankbookPath = state.bankbookPath;
      if (oldBankbookPath != null) {
        await repo.deleteUploadedFile(oldBankbookPath);
      }
      final path = await repo.uploadBankbook(file);
      state = state.copyWith(bankbookPath: path, bankbookFile: file);
      await saveDraft();
    } on Exception catch (e, st) {
      Log.e('uploadBankbook error', e, st);
    }
  }
}
