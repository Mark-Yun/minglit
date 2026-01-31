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

  // --- Step 1: Basic Info ---
  void updateTitle(String value) => state = state.copyWith(title: value);
  void updateDescription(Map<String, dynamic> value) =>
      state = state.copyWith(description: value);
  void updateImages(List<XFile> files) =>
      state = state.copyWith(imageFiles: files);

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

  // --- Step 5: Tickets ---
  void _updateMaxParticipants() {
    final total = state.tickets.fold<int>(0, (sum, t) => sum + t.quantity);
    state = state.copyWith(maxParticipants: total);
  }

  void addTicket(TicketTemplate ticket) {
    state = state.copyWith(tickets: [...state.tickets, ticket]);
    _updateMaxParticipants();
  }

  void updateTicket(int index, TicketTemplate ticket) {
    final list = List<TicketTemplate>.from(state.tickets);
    list[index] = ticket;
    state = state.copyWith(tickets: list);
    _updateMaxParticipants();
  }

  void removeTicket(int index) {
    final list = List<TicketTemplate>.from(state.tickets)..removeAt(index);
    state = state.copyWith(tickets: list);
    _updateMaxParticipants();
  }

  // --- Validation ---
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

  // --- Final Submission ---
  Future<void> submit() async {
    state = state.copyWith(status: const AsyncValue.loading());

    final result = await AsyncValue.guard(() async {
      try {
        // Business Validation
        final errors = validationErrors;
        if (errors.isNotEmpty) {
          throw MinglitUserException(errors.first);
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
        var imageUrls = <String>[];

        // 1. Upload Images
        if (state.imageFiles.isNotEmpty) {
          imageUrls = await partyRepo.uploadPartyImages(
            state.imageFiles,
            partnerId,
          );
        }

        // 2. Prepare Contact Options
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

        // 3. Create Location
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

        // 4. Create Party
        final allVerifIds = state.entryGroups
            .expand((e) => e.requiredVerificationIds)
            .toSet()
            .toList();

        final balanceConfig = <String, dynamic>{
          'enabled': state.balanceEnabled,
          'tolerance': state.balanceTolerance,
        };

        final newParty = Party(
          id: '', // Server generated
          partnerId: partnerId,
          locationId: locationId,
          title: state.title,
          description: state.description,
          minConfirmedCount: state.minConfirmedCount,
          maxParticipants: state.maxParticipants,
          contactOptions: contactOptions,
          entryGroups: state.entryGroups,
          imageUrls: imageUrls,
          requiredVerificationIds: allVerifIds,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final createdParty = await partyRepo.createParty(
          newParty,
          extraFields: {'balance_config': balanceConfig},
        );

        // 5. Create Ticket Templates
        for (final template in state.tickets) {
          await ticketRepo.createTicketTemplate(
            template.copyWith(partyId: createdParty.id),
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
