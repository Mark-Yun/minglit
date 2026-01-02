import 'dart:async';

import 'package:app_partner/src/features/party/list/party_list_controller.dart';
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
    @Default({}) Set<String> enabledContactMethods,

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

  void updateContactPhone(String val) =>
      state = state.copyWith(contactPhone: val);
  void updateContactEmail(String val) =>
      state = state.copyWith(contactEmail: val);
  void updateContactKakao(String val) =>
      state = state.copyWith(contactKakao: val);

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

  void updateEntryGroup(PartyEntryGroup group) {
    state = state.copyWith(
      entryGroups: state.entryGroups
          .map((g) => g.id == group.id ? group : g)
          .toList(),
    );
  }

  void removeEntryGroup(String id) {
    state = state.copyWith(
      entryGroups: state.entryGroups.where((g) => g.id != id).toList(),
    );
  }

  void addTicket(Ticket ticket) {
    state = state.copyWith(tickets: [...state.tickets, ticket]);
  }

  void updateTicket(int index, Ticket ticket) {
    final list = List<Ticket>.from(state.tickets);
    list[index] = ticket;
    state = state.copyWith(tickets: list);
  }

  void removeTicket(int index) {
    final list = List<Ticket>.from(state.tickets)..removeAt(index);
    state = state.copyWith(tickets: list);
  }

  Future<void> submit() async {
    state = state.copyWith(status: const AsyncValue.loading());

    final result = await AsyncValue.guard(() async {
      try {
        // 1. Business Validation
        if (state.selectedLocation == null) {
          throw const MinglitUserException('파티 장소를 선택해주세요.');
        }

        if (state.enabledContactMethods.isEmpty) {
          throw const MinglitUserException('최소 한 개의 문의 연락처를 선택해야 합니다.');
        }

        if (state.entryGroups.isEmpty) {
          throw const MinglitUserException('최소 한 개의 입장 그룹을 생성해야 합니다.');
        }

        if (state.tickets.isEmpty) {
          throw const MinglitUserException('최소 한 개의 티켓 템플릿을 생성해야 합니다.');
        }

        final ops = state.description['ops'] as List?;
        if (ops == null ||
            ops.isEmpty ||
            (ops.length == 1 &&
                (ops[0] as Map<String, dynamic>)['insert'] == '\n')) {
          // Description is basically required
          // We can add error state to Step1 if needed, or just toast
          throw const MinglitUserException('파티 설명을 입력해주세요.');
        }

        final partnerRepo = ref.read(partnerRepositoryProvider);
        final myPartners = await partnerRepo.getMyManagedPartners();
        if (myPartners.isEmpty) {
          throw const MinglitSystemException('사용 가능한 파트너 정보를 찾을 수 없습니다.');
        }
        final partnerId = myPartners.first.id;

        final partyRepo = ref.read(partyRepositoryProvider);
        final locationRepo = ref.read(locationRepositoryProvider);
        final ticketRepo = ref.read(ticketRepositoryProvider);
        String? imageUrl;

        // 2. Upload Image
        if (state.imageFile != null) {
          imageUrl = await partyRepo.uploadPartyImage(
            state.imageFile!,
            partnerId,
          );
        }

        // 3. Prepare Contact Options
        final contactOptions = <String, dynamic>{};
        if (state.enabledContactMethods.contains('phone') &&
            state.contactPhone.isNotEmpty) {
          contactOptions['phone'] = state.contactPhone;
        }
        if (state.enabledContactMethods.contains('email') &&
            state.contactEmail.isNotEmpty) {
          contactOptions['email'] = state.contactEmail;
        }
        if (state.enabledContactMethods.contains('kakao') &&
            state.contactKakao != null &&
            state.contactKakao!.isNotEmpty) {
          contactOptions['kakao_open_chat'] = state.contactKakao;
        }

        // 4. Create Location (if selected)
        String? locationId;
        if (state.selectedLocation != null) {
          final loc = state.selectedLocation!;
          final newLocation = await locationRepo.createLocation(
            loc.copyWith(
              partnerId: partnerId,
              addressDetail: state.addressDetail,
              directionsGuide: state.directionsGuide,
            ),
          );
          locationId = newLocation.id;
        }

        // 5. Create Party
        // Collect all required verification IDs from entry groups for
        // legacy compatibility
        final allVerifIds = state.entryGroups
            .expand((e) => e.requiredVerificationIds)
            .toSet()
            .toList();

        final newParty = Party(
          id: '', // Server generated
          partnerId: partnerId,
          locationId: locationId,
          title: state.title,
          description: state.description,
          minConfirmedCount: state.minConfirmedCount,
          maxParticipants: state.maxParticipants,
          contactOptions: contactOptions,
          conditions: state.entryGroups.map((e) => e.toJson()).toList(),
          imageUrl: imageUrl,
          requiredVerificationIds: allVerifIds,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final createdParty = await partyRepo.createParty(newParty);

        // 6. Create Ticket Templates linked to Party
        for (final template in state.tickets) {
          await ticketRepo.createTicket(
            template.copyWith(
              partyId: createdParty.id,
              eventId: null,
            ),
          );
        }

        // Refresh party list
        ref.invalidate(partyListProvider);
      } catch (e, st) {
        if (e is MinglitException) rethrow;
        throw MinglitSystemException(
          'createParty failed',
          originalError: e,
          stackTrace: st,
        );
      }
    });

    state = state.copyWith(status: result);
  }
}
