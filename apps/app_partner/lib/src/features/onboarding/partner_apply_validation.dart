part of 'partner_apply_controller.dart';

mixin _PartnerApplyValidation on _$PartnerApplyController {
  bool validateStep(int step) {
    return switch (step) {
      0 => state.brandName.isNotEmpty,
      1 =>
        state.bizName.isNotEmpty &&
            state.bizNumber.isNotEmpty &&
            state.representativeName.isNotEmpty,
      2 =>
        state.contactPhone.isNotEmpty &&
            state.contactEmail.isNotEmpty &&
            state.bankName.isNotEmpty &&
            state.accountNumber.isNotEmpty &&
            state.accountHolder.isNotEmpty,
      3 => state.bizRegistrationPath != null && state.bankbookPath != null,
      4 => validateAll(),
      _ => false,
    };
  }

  bool validateAll() {
    return state.brandName.isNotEmpty &&
        state.bizName.isNotEmpty &&
        state.bizNumber.isNotEmpty &&
        state.representativeName.isNotEmpty &&
        state.contactPhone.isNotEmpty &&
        state.contactEmail.isNotEmpty &&
        state.bankName.isNotEmpty &&
        state.accountNumber.isNotEmpty &&
        state.accountHolder.isNotEmpty &&
        state.bizRegistrationPath != null &&
        state.bankbookPath != null;
  }

  void updateField(String field, String value) {
    state = switch (field) {
      'brandName' => state.copyWith(brandName: value),
      'introduction' => state.copyWith(introduction: value),
      'bizType' => state.copyWith(bizType: value),
      'bizName' => state.copyWith(bizName: value),
      'bizNumber' => state.copyWith(bizNumber: value),
      'representativeName' => state.copyWith(representativeName: value),
      'contactPhone' => state.copyWith(contactPhone: value),
      'contactEmail' => state.copyWith(contactEmail: value),
      'address' => state.copyWith(address: value),
      'bankName' => state.copyWith(bankName: value),
      'accountNumber' => state.copyWith(accountNumber: value),
      'accountHolder' => state.copyWith(accountHolder: value),
      'taxEmail' => state.copyWith(taxEmail: value),
      _ => state,
    };
  }
}
