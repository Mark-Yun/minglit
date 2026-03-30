import 'package:app_partner/src/logic/onboarding_state_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'partner_apply_controller.freezed.dart';
part 'partner_apply_controller.g.dart';
part 'partner_apply_steps.dart';
part 'partner_apply_validation.dart';
part 'partner_apply_draft.dart';
part 'partner_apply_submit.dart';

@freezed
abstract class PartnerApplyState with _$PartnerApplyState {
  const factory PartnerApplyState({
    @Default(0) int currentStep,
    String? applicationId,
    @Default(false) bool isSaving,
    @Default(false) bool isSubmitting,
    // Step 1: Basic Info
    @Default('') String brandName,
    @Default('') String introduction,
    String? profileImagePath,
    XFile? profileImageFile,
    // Step 2: Business Info
    @Default('individual') String bizType,
    @Default('') String bizName,
    @Default('') String bizNumber,
    @Default('') String representativeName,
    // Step 3: Contact & Settlement
    @Default('') String contactPhone,
    @Default('') String contactEmail,
    @Default('') String address,
    @Default('') String bankName,
    @Default('') String accountNumber,
    @Default('') String accountHolder,
    @Default('') String taxEmail,
    // Step 4: Documents
    String? bizRegistrationPath,
    XFile? bizRegistrationFile,
    String? bankbookPath,
    XFile? bankbookFile,
    // Global status
    @Default(AsyncValue<void>.data(null)) AsyncValue<void> status,
  }) = _PartnerApplyState;
}

@riverpod
class PartnerApplyController extends _$PartnerApplyController
    with
        _PartnerApplyValidation,
        _PartnerApplyDraft,
        _PartnerApplySteps,
        _PartnerApplySubmit {
  @override
  PartnerApplyState build() {
    return const PartnerApplyState();
  }
}
