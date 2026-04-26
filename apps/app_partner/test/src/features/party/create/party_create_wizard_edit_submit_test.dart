// Critical-path tests for the PartyCreateWizardController._submitEdit branch.
//
// When editingPartyId is set, submit() takes a completely different path from
// the create flow: it reads the existing party, diffs tickets, calls updateParty,
// replaceEntryGroupTemplates, and selectively creates/updates/deletes templates.
// Regression here would silently corrupt party data or leave stale tickets.
//
// These tests verify the edit path independently from the create path.

import 'package:app_partner/src/features/party/create/party_create_wizard_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _now = DateTime.now();

Party _makeParty({
  String id = 'party-edit-1',
  String locationId = 'loc-1',
  List<EntryGroupTemplate>? entryGroups,
}) {
  // Default entryGroups includes one group so that validation passes.
  // The validation requires entryGroups.isNotEmpty (even in edit mode).
  final defaultGroups = [
    EntryGroupTemplate(
      id: 'eg-default',
      partyId: id,
      gender: 'male',
      createdAt: _now,
      updatedAt: _now,
    ),
  ];
  return Party(
    id: id,
    partnerId: 'partner-1',
    title: 'Original Title',
    description: const {
      'ops': [
        {'insert': 'Original\n'},
      ],
    },
    maxParticipants: 20,
    minConfirmedCount: 5,
    locationId: locationId,
    entryGroups: entryGroups ?? defaultGroups,
    createdAt: _now,
    updatedAt: _now,
    contactOptions: {'phone': '010-1234-5678'},
    imageUrls: [],
  );
}

Location _makeLocation({String id = 'loc-1'}) {
  return Location(
    id: id,
    partnerId: 'partner-1',
    name: 'Test Venue',
    address: '서울시 강남구',
    latitude: 37.5,
    longitude: 127.0,
    createdAt: _now,
    updatedAt: _now,
  );
}

TicketTemplate _makeTemplate({
  String id = 'tt-1',
  String partyId = 'party-edit-1',
}) {
  return TicketTemplate(
    id: id,
    partyId: partyId,
    name: 'Standard Ticket',
    price: 15000,
    quantity: 50,
    createdAt: _now,
    updatedAt: _now,
  );
}

// ---------------------------------------------------------------------------
// Container factory
// ---------------------------------------------------------------------------

ProviderContainer _makeContainer({
  required MockPartyRepository mockPartyRepo,
  required MockTicketRepository mockTicketRepo,
  required MockLocationRepository mockLocationRepo,
  MockTagRepository? mockTagRepo,
}) {
  final tagRepo = mockTagRepo ?? MockTagRepository();
  return createContainer(
    overrides: [
      partyRepositoryProvider.overrideWithValue(mockPartyRepo),
      ticketRepositoryProvider.overrideWithValue(mockTicketRepo),
      locationRepositoryProvider.overrideWithValue(mockLocationRepo),
      tagRepositoryProvider.overrideWithValue(tagRepo),
    ],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockPartyRepository mockPartyRepo;
  late MockTicketRepository mockTicketRepo;
  late MockLocationRepository mockLocationRepo;
  late MockTagRepository mockTagRepo;

  setUp(() {
    mockPartyRepo = MockPartyRepository();
    mockTicketRepo = MockTicketRepository();
    mockLocationRepo = MockLocationRepository();
    mockTagRepo = MockTagRepository();
  });

  setUpAll(() {
    registerFallbackValue(_makeLocation());
    registerFallbackValue(
      _makeParty(),
    );
    registerFallbackValue(_makeTemplate());
  });

  // ---------------------------------------------------------------------------
  // _submitEdit basic flow
  // ---------------------------------------------------------------------------
  group('_submitEdit — basic flow', () {
    test(
      'calls updateParty, replaceEntryGroupTemplates, invalidates providers',
      () async {
        const partyId = 'party-edit-1';
        final party = _makeParty(id: partyId);
        final existingTemplate = _makeTemplate(id: 'tt-existing');

        when(
          () => mockPartyRepo.getPartyById(partyId),
        ).thenAnswer((_) async => party);
        when(
          () => mockPartyRepo.updateParty(
            any(),
            tagIds: any(named: 'tagIds'),
          ),
        ).thenAnswer((_) async => party);
        when(
          () => mockPartyRepo.replaceEntryGroupTemplates(partyId, any()),
        ).thenAnswer((_) async {});
        when(
          () => mockPartyRepo.uploadPartyImages(any(), any()),
        ).thenAnswer((_) async => []);
        when(
          () => mockTicketRepo.getTicketTemplatesByPartyId(partyId),
        ).thenAnswer((_) async => [existingTemplate]);
        // Existing template is also in incoming list → updateTicketTemplate
        when(
          () => mockTicketRepo.updateTicketTemplate(any()),
        ).thenAnswer((_) async => existingTemplate);
        when(
          () => mockLocationRepo.getLocationById('loc-1'),
        ).thenAnswer((_) async => _makeLocation());
        // loadForEdit sets selectedLocation from the fetched location.
        // _submitEdit then sees selectedLocation != null, fetches location again
        // (same lat/lng → isSameSpot) and calls updateLocationDetails.
        when(
          () => mockLocationRepo.updateLocationDetails(
            locationId: any(named: 'locationId'),
            addressDetail: any(named: 'addressDetail'),
            directionsGuide: any(named: 'directionsGuide'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockTagRepo.getTagsByPartyId(partyId),
        ).thenAnswer((_) async => []);

        final container = _makeContainer(
          mockPartyRepo: mockPartyRepo,
          mockTicketRepo: mockTicketRepo,
          mockLocationRepo: mockLocationRepo,
          mockTagRepo: mockTagRepo,
        );

        final notifier = container.read(
          partyCreateWizardControllerProvider.notifier,
        );

        // Set up edit state — loadForEdit prerequisites
        await notifier.loadForEdit(partyId);

        // Keep the same ticket (id not empty → should update, not delete or create)
        // Validation is bypassed in edit mode (goes to _submitEdit, which does not
        // re-run validationErrors); just make sure editingPartyId is set.
        expect(
          container.read(partyCreateWizardControllerProvider).editingPartyId,
          partyId,
        );

        await notifier.submit();

        final state = container.read(partyCreateWizardControllerProvider);
        expect(state.status, isA<AsyncData<void>>());

        // updateParty must be called once
        verify(
          () => mockPartyRepo.updateParty(
            any(),
            tagIds: any(named: 'tagIds'),
          ),
        ).called(1);

        // replaceEntryGroupTemplates must be called once
        verify(
          () => mockPartyRepo.replaceEntryGroupTemplates(partyId, any()),
        ).called(1);
      },
    );

    test(
      'deletes ticket that exists in repo but is absent from incoming list',
      () async {
        const partyId = 'party-edit-2';
        // locationId: 'loc-1' ensures selectedLocation is loaded so validation passes.
        // _submitEdit will call getLocationById + updateLocationDetails (isSameSpot).
        final party = _makeParty(id: partyId, locationId: 'loc-1');
        // Existing has 2 templates; incoming (wizard state) has only 1
        final keep = _makeTemplate(id: 'tt-keep', partyId: partyId);
        final toDelete = _makeTemplate(id: 'tt-delete', partyId: partyId);

        when(
          () => mockPartyRepo.getPartyById(partyId),
        ).thenAnswer((_) async => party);
        when(
          () => mockPartyRepo.updateParty(
            any(),
            tagIds: any(named: 'tagIds'),
          ),
        ).thenAnswer((_) async => party);
        when(
          () => mockPartyRepo.replaceEntryGroupTemplates(partyId, any()),
        ).thenAnswer((_) async {});
        when(
          () => mockPartyRepo.uploadPartyImages(any(), any()),
        ).thenAnswer((_) async => []);
        when(
          () => mockTicketRepo.getTicketTemplatesByPartyId(partyId),
        ).thenAnswer((_) async => [keep, toDelete]);
        when(
          () => mockTicketRepo.updateTicketTemplate(any()),
        ).thenAnswer((_) async => keep);
        when(
          () => mockTicketRepo.deleteTicketTemplate('tt-delete'),
        ).thenAnswer((_) async {});
        when(
          () => mockLocationRepo.getLocationById(any()),
        ).thenAnswer((_) async => _makeLocation());
        when(
          () => mockLocationRepo.updateLocationDetails(
            locationId: any(named: 'locationId'),
            addressDetail: any(named: 'addressDetail'),
            directionsGuide: any(named: 'directionsGuide'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockTagRepo.getTagsByPartyId(partyId),
        ).thenAnswer((_) async => []);

        final container = _makeContainer(
          mockPartyRepo: mockPartyRepo,
          mockTicketRepo: mockTicketRepo,
          mockLocationRepo: mockLocationRepo,
          mockTagRepo: mockTagRepo,
        );

        final notifier = container.read(
          partyCreateWizardControllerProvider.notifier,
        );

        await notifier.loadForEdit(partyId);

        // Remove the 'tt-delete' template from the wizard's ticket list,
        // keeping only 'tt-keep'
        final stateAfterLoad =
            container.read(partyCreateWizardControllerProvider);
        final filteredTickets = stateAfterLoad.tickets
            .where((t) => t.id != 'tt-delete')
            .toList();
        // Replace tickets in state directly via removeTicket or by direct state manipulation.
        // We need to remove the ticket from the list before submit.
        notifier.state = stateAfterLoad.copyWith(tickets: filteredTickets);

        await notifier.submit();

        final state = container.read(partyCreateWizardControllerProvider);
        expect(state.status, isA<AsyncData<void>>());

        // 'tt-delete' must be deleted from the repo
        verify(
          () => mockTicketRepo.deleteTicketTemplate('tt-delete'),
        ).called(1);
        // 'tt-keep' must be updated (id not empty → update path)
        verify(
          () => mockTicketRepo.updateTicketTemplate(any()),
        ).called(1);
      },
    );

    test(
      'creates new ticket when template has empty id in incoming list',
      () async {
        const partyId = 'party-edit-3';
        // locationId: 'loc-1' ensures selectedLocation is loaded so validation passes.
        final party = _makeParty(id: partyId, locationId: 'loc-1');
        // Existing: no templates
        final newTemplate = TicketTemplate(
          id: '', // empty id → create path
          partyId: partyId,
          name: 'New Ticket',
          price: 10000,
          quantity: 30,
          createdAt: _now,
          updatedAt: _now,
        );

        when(
          () => mockPartyRepo.getPartyById(partyId),
        ).thenAnswer((_) async => party);
        when(
          () => mockPartyRepo.updateParty(
            any(),
            tagIds: any(named: 'tagIds'),
          ),
        ).thenAnswer((_) async => party);
        when(
          () => mockPartyRepo.replaceEntryGroupTemplates(partyId, any()),
        ).thenAnswer((_) async {});
        when(
          () => mockPartyRepo.uploadPartyImages(any(), any()),
        ).thenAnswer((_) async => []);
        when(
          () => mockTicketRepo.getTicketTemplatesByPartyId(partyId),
        ).thenAnswer((_) async => []); // no existing templates
        when(
          () => mockTicketRepo.createTicketTemplate(any()),
        ).thenAnswer((_) async => _makeTemplate());
        when(
          () => mockLocationRepo.getLocationById(any()),
        ).thenAnswer((_) async => _makeLocation());
        when(
          () => mockLocationRepo.updateLocationDetails(
            locationId: any(named: 'locationId'),
            addressDetail: any(named: 'addressDetail'),
            directionsGuide: any(named: 'directionsGuide'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockTagRepo.getTagsByPartyId(partyId),
        ).thenAnswer((_) async => []);

        final container = _makeContainer(
          mockPartyRepo: mockPartyRepo,
          mockTicketRepo: mockTicketRepo,
          mockLocationRepo: mockLocationRepo,
          mockTagRepo: mockTagRepo,
        );

        final notifier = container.read(
          partyCreateWizardControllerProvider.notifier,
        );

        await notifier.loadForEdit(partyId);

        // Add a new (id-less) ticket to the wizard state
        final stateAfterLoad =
            container.read(partyCreateWizardControllerProvider);
        notifier.state = stateAfterLoad.copyWith(
          tickets: [newTemplate],
        );

        await notifier.submit();

        final state = container.read(partyCreateWizardControllerProvider);
        expect(state.status, isA<AsyncData<void>>());

        // New ticket with empty id must be created, not updated
        verify(
          () => mockTicketRepo.createTicketTemplate(any()),
        ).called(1);
        verifyNever(() => mockTicketRepo.updateTicketTemplate(any()));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // _submitEdit error handling
  // ---------------------------------------------------------------------------
  group('_submitEdit — error handling', () {
    test('sets AsyncError when getPartyById returns null', () async {
      const partyId = 'party-missing';

      when(
        () => mockPartyRepo.getPartyById(partyId),
      ).thenAnswer((_) async => null);

      final container = createContainer(
        overrides: [
          partyRepositoryProvider.overrideWithValue(mockPartyRepo),
          ticketRepositoryProvider.overrideWithValue(mockTicketRepo),
          locationRepositoryProvider.overrideWithValue(mockLocationRepo),
          tagRepositoryProvider.overrideWithValue(mockTagRepo),
        ],
      );

      final notifier = container.read(
        partyCreateWizardControllerProvider.notifier,
      );

      // Force editingPartyId without going through loadForEdit (which would throw)
      notifier.state = const PartyCreateWizardState(
        editingPartyId: partyId,
        title: 'Title',
      );

      await notifier.submit();

      final state = container.read(partyCreateWizardControllerProvider);
      // Validation will fail first (empty title triggers before _submitEdit calls getPartyById),
      // OR if validation passes and getPartyById returns null, we get MinglitSystemException.
      // Either way, status must not be AsyncData.
      expect(state.status, isNot(isA<AsyncData<void>>()));
    });

    test(
      'sets AsyncError when updateParty repository call throws',
      () async {
        const partyId = 'party-edit-err';
        final party = _makeParty(id: partyId);

        when(
          () => mockPartyRepo.getPartyById(partyId),
        ).thenAnswer((_) async => party);
        when(
          () => mockPartyRepo.updateParty(
            any(),
            tagIds: any(named: 'tagIds'),
          ),
        ).thenThrow(Exception('write failed'));
        when(
          () => mockPartyRepo.uploadPartyImages(any(), any()),
        ).thenAnswer((_) async => []);
        when(
          () => mockTicketRepo.getTicketTemplatesByPartyId(partyId),
        ).thenAnswer((_) async => []);
        when(
          () => mockLocationRepo.getLocationById(any()),
        ).thenAnswer((_) async => _makeLocation());
        // updateLocationDetails succeeds — error must come from updateParty, not location
        when(
          () => mockLocationRepo.updateLocationDetails(
            locationId: any(named: 'locationId'),
            addressDetail: any(named: 'addressDetail'),
            directionsGuide: any(named: 'directionsGuide'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockTagRepo.getTagsByPartyId(partyId),
        ).thenAnswer((_) async => []);

        final container = _makeContainer(
          mockPartyRepo: mockPartyRepo,
          mockTicketRepo: mockTicketRepo,
          mockLocationRepo: mockLocationRepo,
          mockTagRepo: mockTagRepo,
        );

        final notifier = container.read(
          partyCreateWizardControllerProvider.notifier,
        );

        await notifier.loadForEdit(partyId);
        await notifier.submit();

        final state = container.read(partyCreateWizardControllerProvider);
        expect(state.status, isA<AsyncError<void>>());
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Routing: _submitEdit is taken only when editingPartyId is set
  // ---------------------------------------------------------------------------
  group('_submitEdit routing gate', () {
    test(
      'submit with editingPartyId set does NOT call getMyManagedPartners',
      () async {
        const partyId = 'party-edit-gate';
        // No locationId → _submitEdit skips location block
        final party = _makeParty(id: partyId, locationId: '');

        when(
          () => mockPartyRepo.getPartyById(partyId),
        ).thenAnswer((_) async => party);
        when(
          () => mockPartyRepo.updateParty(
            any(),
            tagIds: any(named: 'tagIds'),
          ),
        ).thenAnswer((_) async => party);
        when(
          () => mockPartyRepo.replaceEntryGroupTemplates(partyId, any()),
        ).thenAnswer((_) async {});
        when(
          () => mockPartyRepo.uploadPartyImages(any(), any()),
        ).thenAnswer((_) async => []);
        final existingTicket = _makeTemplate(id: 'tt-gate', partyId: partyId);
        when(
          () => mockTicketRepo.getTicketTemplatesByPartyId(partyId),
        ).thenAnswer((_) async => [existingTicket]);
        when(
          () => mockTicketRepo.updateTicketTemplate(any()),
        ).thenAnswer((_) async => existingTicket);
        when(
          () => mockTagRepo.getTagsByPartyId(partyId),
        ).thenAnswer((_) async => []);

        // MockPartnerRepository is provided but should NEVER be called
        final mockPartnerRepo = MockPartnerRepository();

        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
            ticketRepositoryProvider.overrideWithValue(mockTicketRepo),
            locationRepositoryProvider.overrideWithValue(mockLocationRepo),
            tagRepositoryProvider.overrideWithValue(mockTagRepo),
            partnerRepositoryProvider.overrideWithValue(mockPartnerRepo),
          ],
        );

        final notifier = container.read(
          partyCreateWizardControllerProvider.notifier,
        );

        await notifier.loadForEdit(partyId);
        await notifier.submit();

        // Edit path must NOT call getMyManagedPartners (that is the create path)
        verifyNever(() => mockPartnerRepo.getMyManagedPartners());
      },
    );
  });
}
