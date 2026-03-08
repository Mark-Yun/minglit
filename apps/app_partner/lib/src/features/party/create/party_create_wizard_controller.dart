import 'dart:async';

import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/list/party_list_controller.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'party_create_wizard_controller.freezed.dart';
part 'party_create_wizard_controller.g.dart';
part 'party_create_wizard_load.dart';
part 'party_create_wizard_steps.dart';
part 'party_create_wizard_tickets.dart';
part 'party_create_wizard_validation.dart';
part 'party_create_wizard_submit.dart';

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
    @Default(true) bool isPrefilled,
    String? editingPartyId,

    // Step 1: Basic Info
    @Default('') String title,
    @Default({}) Map<String, dynamic> description,
    @Default([]) List<String> imageUrls,
    @Default([]) List<XFile> imageFiles,

    // Step 2: Location
    Location? selectedLocation,
    @Default('') String addressDetail,
    @Default('') String directionsGuide,

    // Step 3: Capacity & Contact
    @Default(5) int minConfirmedCount,
    @Default(0) int maxParticipants,
    @Default('') String contactPhone,
    @Default('') String contactEmail,
    String? contactKakao,
    @Default({}) Set<String> enabledContactMethods,
    @Default(false) bool balanceEnabled,
    @Default(2) int balanceTolerance,

    // Step 4: Entry Rules (Entry Groups)
    @Default([]) List<EntryGroupTemplate> entryGroups,

    // Step 5: Ticket Templates
    @Default([]) List<TicketTemplate> tickets,

    // Global Status
    @Default(AsyncValue.data(null)) AsyncValue<void> status,
  }) = _PartyCreateWizardState;
}

@riverpod
class PartyCreateWizardController extends _$PartyCreateWizardController
    with
        _PartyCreateWizardLoad,
        _PartyCreateWizardSteps,
        _PartyCreateWizardTickets,
        _PartyCreateWizardValidation,
        _PartyCreateWizardSubmit {
  @override
  PartyCreateWizardState build() {
    return const PartyCreateWizardState();
  }
}
