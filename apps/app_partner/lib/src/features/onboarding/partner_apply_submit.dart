part of 'partner_apply_controller.dart';

mixin _PartnerApplySubmit on _$PartnerApplyController, _PartnerApplyValidation {
  Future<void> submit() async {
    if (!validateAll()) return;
    // Fix #1599: applicationId is null when all prior saveDraft calls failed — surface error.
    if (state.applicationId == null) {
      state = state.copyWith(
        status: AsyncValue.error(
          Exception('임시저장에 실패했습니다. 잠시 후 다시 시도해주세요.'),
          StackTrace.current,
        ),
      );
      return;
    }

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
