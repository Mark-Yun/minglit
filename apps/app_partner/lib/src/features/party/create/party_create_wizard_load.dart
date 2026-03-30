part of 'party_create_wizard_controller.dart';

mixin _PartyCreateWizardLoad on _$PartyCreateWizardController {
  Future<void> loadForEdit(String partyId) async {
    state = state.copyWith(editingPartyId: partyId, isPrefilled: false);

    final partyRepo = ref.read(partyRepositoryProvider);
    final ticketRepo = ref.read(ticketRepositoryProvider);
    final locationRepo = ref.read(locationRepositoryProvider);

    final party = await partyRepo.getPartyById(partyId);
    if (party == null) {
      throw const MinglitSystemException('파티 정보를 찾을 수 없습니다.');
    }

    final templates = await ticketRepo.getTicketTemplatesByPartyId(partyId);
    Location? location;
    final locationId = party.locationId;
    if (locationId != null && locationId.isNotEmpty) {
      location = await locationRepo.getLocationById(locationId);
    }

    final contactOptions = party.contactOptions;
    final enabledMethods = <String>{};
    final phone = (contactOptions['phone'] ?? '').toString();
    if (phone.isNotEmpty) enabledMethods.add('phone');
    final email = (contactOptions['email'] ?? '').toString();
    if (email.isNotEmpty) enabledMethods.add('email');
    final kakao = (contactOptions['kakao_open_chat'] ?? '').toString();
    if (kakao.isNotEmpty) enabledMethods.add('kakao');

    state = state.copyWith(
      title: party.title,
      description: party.description ?? {},
      imageUrls: party.imageUrls,
      imageFiles: [],
      selectedLocation: location,
      addressDetail: location?.addressDetail ?? '',
      directionsGuide: location?.directionsGuide ?? '',
      minConfirmedCount: party.minConfirmedCount,
      maxParticipants: party.maxParticipants,
      contactPhone: phone,
      contactEmail: email,
      contactKakao: kakao.isEmpty ? null : kakao,
      enabledContactMethods: enabledMethods,
      entryGroups: party.entryGroups ?? [],
      tickets: templates,
      isPrefilled: true,
    );
  }
}
