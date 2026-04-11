part of 'party_create_wizard_controller.dart';

mixin _PartyCreateWizardSubmit
    on _$PartyCreateWizardController, _PartyCreateWizardValidation {
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

        if (state.editingPartyId != null) {
          await _submitEdit();
          return;
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
            (state.contactKakao?.isNotEmpty ?? false)) {
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
          extraFields: {
            'balance_config': balanceConfig,
            'visibility': state.visibility,
            if (state.tagIds.isNotEmpty) 'tag_ids': state.tagIds,
          },
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

  Future<void> _submitEdit() async {
    final partyId = state.editingPartyId;
    if (partyId == null) return;

    final partyRepo = ref.read(partyRepositoryProvider);
    final ticketRepo = ref.read(ticketRepositoryProvider);
    final locationRepo = ref.read(locationRepositoryProvider);

    final party = await partyRepo.getPartyById(partyId);
    if (party == null) {
      throw const MinglitSystemException('수정할 파티 정보를 찾을 수 없습니다.');
    }

    final imageUrls = [...state.imageUrls];
    if (state.imageFiles.isNotEmpty) {
      final uploaded = await partyRepo.uploadPartyImages(
        state.imageFiles,
        party.partnerId,
      );
      imageUrls.addAll(uploaded);
    }

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
        (state.contactKakao?.isNotEmpty ?? false)) {
      contactOptions['kakao_open_chat'] = state.contactKakao;
    }

    if (state.selectedLocation != null) {
      final currentLocation = party.locationId != null
          ? await locationRepo.getLocationById(party.locationId!)
          : null;

      final newLocation = state.selectedLocation!;
      final isSameSpot =
          currentLocation != null &&
          currentLocation.latitude == newLocation.latitude &&
          currentLocation.longitude == newLocation.longitude;

      if (isSameSpot) {
        await locationRepo.updateLocationDetails(
          locationId: currentLocation.id,
          addressDetail: state.addressDetail,
          directionsGuide: state.directionsGuide,
        );
      } else {
        final savedLocation = await locationRepo.createLocation(
          newLocation.copyWith(
            partnerId: party.partnerId,
            addressDetail: state.addressDetail,
            directionsGuide: state.directionsGuide,
          ),
        );
        await partyRepo.updatePartyLocation(party.id, savedLocation.id);
      }
    }

    final allVerifIds = state.entryGroups
        .expand((e) => e.requiredVerificationIds)
        .toSet()
        .toList();

    await partyRepo.updateParty(
      party.copyWith(
        title: state.title,
        description: state.description,
        minConfirmedCount: state.minConfirmedCount,
        maxParticipants: state.maxParticipants,
        contactOptions: contactOptions,
        imageUrls: imageUrls,
        requiredVerificationIds: allVerifIds,
        updatedAt: DateTime.now(),
      ),
      // tag_ids를 항상 전달하여 EF에서 party_tags를 동기화한다
      // (빈 리스트 = 기존 태그 전체 제거)
      tagIds: state.tagIds,
    );

    await partyRepo.replaceEntryGroupTemplates(partyId, state.entryGroups);

    final existingTemplates = await ticketRepo.getTicketTemplatesByPartyId(
      partyId,
    );
    final incomingIds = state.tickets
        .where((template) => template.id.isNotEmpty)
        .map((template) => template.id)
        .toSet();

    for (final template in existingTemplates) {
      if (!incomingIds.contains(template.id)) {
        await ticketRepo.deleteTicketTemplate(template.id);
      }
    }

    for (final template in state.tickets) {
      if (template.id.isEmpty) {
        await ticketRepo.createTicketTemplate(
          template.copyWith(partyId: partyId),
        );
      } else {
        await ticketRepo.updateTicketTemplate(
          template.copyWith(partyId: partyId, updatedAt: DateTime.now()),
        );
      }
    }

    ref
      ..invalidate(partyDetailProvider(partyId))
      ..invalidate(partyTicketsProvider(partyId))
      ..invalidate(partyListProvider);
  }
}
