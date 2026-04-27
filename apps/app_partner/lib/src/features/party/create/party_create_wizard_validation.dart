part of 'party_create_wizard_controller.dart';

mixin _PartyCreateWizardValidation on _$PartyCreateWizardController {
  // --- Per-step validation ---
  // Fix #1836: validate each step before allowing forward navigation
  List<String> get currentStepValidationErrors {
    switch (state.currentStep) {
      case PartyCreateStep.basicInfo:
        final errors = <String>[];
        if (state.title.trim().isEmpty) errors.add('파티 제목을 입력해주세요.');
        final ops = state.description['ops'] as List?;
        final isDescriptionEmpty =
            ops == null ||
            ops.isEmpty ||
            (ops.length == 1 &&
                (ops[0] as Map<String, dynamic>)['insert'] == '\n');
        if (isDescriptionEmpty) errors.add('파티 상세 설명을 입력해주세요.');
        return errors;
      case PartyCreateStep.location:
        if (state.selectedLocation == null) return ['파티 장소를 선택해주세요.'];
        return [];
      case PartyCreateStep.capacityAndContact:
        if (state.enabledContactMethods.isEmpty) {
          return ['최소 한 개의 문의 연락처를 활성화해야 합니다.'];
        }
        if (state.minConfirmedCount > state.maxParticipants) {
          return [
            '최소 확정 인원(${state.minConfirmedCount}명)이 '
                '최대 정원(${state.maxParticipants}명)보다 많습니다.',
          ];
        }
        return [];
      case PartyCreateStep.entryRules:
        if (state.entryGroups.isEmpty) return ['최소 한 개의 입장 그룹을 생성해야 합니다.'];
        return [];
      case PartyCreateStep.tickets:
        if (state.tickets.isEmpty) return ['최소 한 개의 티켓을 생성해야 합니다.'];
        return [];
      case PartyCreateStep.review:
        return [];
    }
  }

  // --- Full validation (used at review step) ---
  List<String> get validationErrors {
    final errors = <String>[];

    if (state.title.trim().isEmpty) {
      errors.add('파티 제목을 입력해주세요.');
    }

    final ops = state.description['ops'] as List?;
    final isDescriptionEmpty =
        ops == null ||
        ops.isEmpty ||
        (ops.length == 1 && (ops[0] as Map<String, dynamic>)['insert'] == '\n');
    if (isDescriptionEmpty) {
      errors.add('파티 상세 설명을 입력해주세요.');
    }

    if (state.selectedLocation == null) {
      errors.add('파티 장소를 선택해주세요.');
    }

    if (state.enabledContactMethods.isEmpty) {
      errors.add('최소 한 개의 문의 연락처를 활성화해야 합니다.');
    }

    if (state.entryGroups.isEmpty) {
      errors.add('최소 한 개의 입장 그룹을 생성해야 합니다.');
    }

    if (state.tickets.isEmpty) {
      errors.add('최소 한 개의 티켓을 생성해야 합니다.');
    }

    // Capacity Check: Ensure min is not more than current total max
    if (state.minConfirmedCount > state.maxParticipants) {
      errors.add(
        '최소 확정 인원(${state.minConfirmedCount}명)이 '
        '최대 정원(${state.maxParticipants}명)보다 많습니다.',
      );
    }

    return errors;
  }
}
