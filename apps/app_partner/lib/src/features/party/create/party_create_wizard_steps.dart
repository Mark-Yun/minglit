part of 'party_create_wizard_controller.dart';

mixin _PartyCreateWizardSteps on _$PartyCreateWizardController {
  void nextStep() {
    final nextIndex = state.currentStep.index + 1;
    if (nextIndex < PartyCreateStep.values.length) {
      state = state.copyWith(currentStep: PartyCreateStep.values[nextIndex]);
    }
  }

  void previousStep() {
    final prevIndex = state.currentStep.index - 1;
    if (prevIndex >= 0) {
      state = state.copyWith(currentStep: PartyCreateStep.values[prevIndex]);
    }
  }

  void setStep(PartyCreateStep step) {
    state = state.copyWith(currentStep: step);
  }

  // --- Step 1: Basic Info ---
  void updateTitle(String value) => state = state.copyWith(title: value);
  void updateDescription(Map<String, dynamic> value) =>
      state = state.copyWith(description: value);
  void updateImages({
    required List<String> imageUrls,
    required List<XFile> newFiles,
  }) =>
      state = state.copyWith(imageUrls: imageUrls, imageFiles: newFiles);

  void setVisibility(String value) => state = state.copyWith(visibility: value);

  // --- Step 2: Location ---
  void updateLocation(Location? loc) =>
      state = state.copyWith(selectedLocation: loc);
  void updateAddressDetail(String val) =>
      state = state.copyWith(addressDetail: val);
  void updateDirections(String val) =>
      state = state.copyWith(directionsGuide: val);

  // --- Step 3: Capacity & Contact ---
  void updateCapacity({int? min}) {
    state = state.copyWith(
      minConfirmedCount: min ?? state.minConfirmedCount,
    );
  }

  void updateContactPhone(String val) =>
      state = state.copyWith(contactPhone: val);
  void updateContactEmail(String val) =>
      state = state.copyWith(contactEmail: val);
  void updateContactKakao(String val) =>
      state = state.copyWith(contactKakao: val);

  void toggleBalance() =>
      state = state.copyWith(balanceEnabled: !state.balanceEnabled);
  void updateBalanceTolerance(int val) =>
      state = state.copyWith(balanceTolerance: val);

  void toggleContactMethod(String method) {
    final current = Set<String>.from(state.enabledContactMethods);
    if (current.contains(method)) {
      current.remove(method);
    } else {
      current.add(method);
    }
    state = state.copyWith(enabledContactMethods: current);
  }

  // --- Step 4: Entry Groups ---
  void addEntryGroup(EntryGroupTemplate group) {
    state = state.copyWith(entryGroups: [...state.entryGroups, group]);
  }

  void updateEntryGroup(EntryGroupTemplate group) {
    state = state.copyWith(
      entryGroups:
          state.entryGroups.map((g) => g.id == group.id ? group : g).toList(),
    );
  }

  void removeEntryGroup(String id) {
    state = state.copyWith(
      entryGroups: state.entryGroups.where((g) => g.id != id).toList(),
    );
  }
}
