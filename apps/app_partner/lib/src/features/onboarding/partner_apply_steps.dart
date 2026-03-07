part of 'partner_apply_controller.dart';

mixin _PartnerApplySteps
    on _$PartnerApplyController, _PartnerApplyValidation, _PartnerApplyDraft {
  static const int totalSteps = 5;

  Future<void> nextStep() async {
    if (state.currentStep < totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
      await saveDraft();
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setStep(int step) {
    if (step >= 0 && step < totalSteps) {
      state = state.copyWith(currentStep: step);
    }
  }

  bool canProceed() => validateStep(state.currentStep);
}
