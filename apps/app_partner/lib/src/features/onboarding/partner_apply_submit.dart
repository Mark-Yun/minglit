part of 'partner_apply_controller.dart';

mixin _PartnerApplySubmit on _$PartnerApplyController, _PartnerApplyValidation {
  Future<void> submit() async {
    if (!validateAll()) return;
    if (state.applicationId == null) return;

    state = state.copyWith(
      isSubmitting: true,
      status: const AsyncValue.loading(),
    );

    final result = await AsyncValue.guard(() async {
      final repo = ref.read(partnerRepositoryProvider);
      await repo.submitDraft(applicationId: state.applicationId!);
      ref.invalidate(onboardingStateProvider);
    });

    state = state.copyWith(isSubmitting: false, status: result);
  }
}
