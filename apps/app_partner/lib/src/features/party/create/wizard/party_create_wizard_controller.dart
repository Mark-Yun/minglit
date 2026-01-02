import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'party_create_wizard_controller.freezed.dart';
part 'party_create_wizard_controller.g.dart';

enum PartyCreateStep {
  basicInfo,
  location,
  capacityAndContact,
  entryRules,
  tickets,
  review,
}

@freezed
abstract class PartyCreateWizardState with _$PartyCreateWizardState {
  const factory PartyCreateWizardState({
    @Default(PartyCreateStep.basicInfo) PartyCreateStep currentStep,

    // Step 1: Basic Info
    @Default('') String title,
    @Default({}) Map<String, dynamic> description,
    XFile? imageFile,

    // Step 2: Location
    Location? selectedLocation,
    String? addressDetail,
    String? directionsGuide,

    // Step 3: Capacity & Contact
    @Default(5) int minConfirmedCount,
    @Default(20) int maxParticipants,
    @Default('') String contactPhone,
    @Default('') String contactEmail,
    String? contactKakao,
    @Default({'phone', 'email'}) Set<String> enabledContactMethods,

    // Step 4: Entry Rules (Entry Groups)
    @Default([]) List<PartyEntryGroup> entryGroups,

    // Step 5: Tickets
    @Default([]) List<Ticket> tickets,

    // Global Status
    @Default(AsyncValue.data(null)) AsyncValue<void> status,
  }) = _PartyCreateWizardState;
}

@riverpod
class PartyCreateWizardController extends _$PartyCreateWizardController {
  @override
  PartyCreateWizardState build() {
    return const PartyCreateWizardState();
  }

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

  // Update Methods for each field...
  void updateTitle(String value) => state = state.copyWith(title: value);
  void updateDescription(Map<String, dynamic> value) =>
      state = state.copyWith(description: value);
  void updateImage(XFile? file) => state = state.copyWith(imageFile: file);

  void updateLocation(Location? loc) =>
      state = state.copyWith(selectedLocation: loc);
  void updateAddressDetail(String? val) =>
      state = state.copyWith(addressDetail: val);
  void updateDirections(String? val) =>
      state = state.copyWith(directionsGuide: val);

  void updateCapacity({int? min, int? max}) {
    state = state.copyWith(
      minConfirmedCount: min ?? state.minConfirmedCount,
      maxParticipants: max ?? state.maxParticipants,
    );
  }

  void toggleContactMethod(String method) {
    final current = Set<String>.from(state.enabledContactMethods);
    if (current.contains(method)) {
      current.remove(method);
    } else {
      current.add(method);
    }
    state = state.copyWith(enabledContactMethods: current);
  }

  void addEntryGroup(PartyEntryGroup group) {
    state = state.copyWith(entryGroups: [...state.entryGroups, group]);
  }

  void removeEntryGroup(String id) {
    state = state.copyWith(
      entryGroups: state.entryGroups.where((g) => g.id != id).toList(),
    );
  }

  void addTicket(Ticket ticket) {
    state = state.copyWith(tickets: [...state.tickets, ticket]);
  }

  void removeTicket(int index) {
    final list = List<Ticket>.from(state.tickets)..removeAt(index);
    state = state.copyWith(tickets: list);
  }

  Future<void> submit() async {
    // TODO(developer): Implement final submission logic
    state = state.copyWith(status: const AsyncValue.loading());
    final result = await AsyncValue.guard(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
    });
    state = state.copyWith(status: result);
  }
}
