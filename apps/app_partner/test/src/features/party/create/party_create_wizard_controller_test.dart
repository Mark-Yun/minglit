import 'package:app_partner/src/features/party/create/party_create_wizard_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

Future<void> pump() async {
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

final _now = DateTime.now();
final _dummyLocation = Location(
  id: '',
  partnerId: '',
  name: '',
  address: '',
  createdAt: _now,
  updatedAt: _now,
);
final _dummyParty = Party(
  id: '',
  partnerId: '',
  title: '',
  createdAt: _now,
  updatedAt: _now,
);
final _dummyTicket = TicketTemplate(
  id: '',
  partyId: '',
  name: '',
  createdAt: _now,
  updatedAt: _now,
);

void main() {
  setUpAll(() {
    registerFallbackValue(_dummyLocation);
    registerFallbackValue(_dummyParty);
    registerFallbackValue(_dummyTicket);
  });

  late MockPartyRepository mockPartyRepo;
  late MockPartnerRepository mockPartnerRepo;
  late MockTicketRepository mockTicketRepo;
  late MockLocationRepository mockLocationRepo;
  late MockTagRepository mockTagRepo;

  setUp(() {
    mockPartyRepo = MockPartyRepository();
    mockPartnerRepo = MockPartnerRepository();
    mockTicketRepo = MockTicketRepository();
    mockLocationRepo = MockLocationRepository();
    mockTagRepo = MockTagRepository();
  });

  ProviderContainer makeContainer() {
    return createContainer(
      overrides: [
        partyRepositoryProvider.overrideWithValue(mockPartyRepo),
        partnerRepositoryProvider.overrideWithValue(mockPartnerRepo),
        ticketRepositoryProvider.overrideWithValue(mockTicketRepo),
        locationRepositoryProvider.overrideWithValue(mockLocationRepo),
        tagRepositoryProvider.overrideWithValue(mockTagRepo),
      ],
    );
  }

  group('PartyCreateWizardController', () {
    test('initial state has default values', () {
      final container = makeContainer();
      final state = container.read(partyCreateWizardControllerProvider);

      expect(state.currentStep, PartyCreateStep.basicInfo);
      expect(state.title, '');
      expect(state.description, isEmpty);
      expect(state.imageUrls, isEmpty);
      expect(state.minConfirmedCount, 5);
      expect(state.maxParticipants, 0);
      expect(state.visibility, 'public');
      expect(state.status, isA<AsyncData<void>>());
    });

    group('step navigation', () {
      test('nextStep advances step', () {
        final container = makeContainer();
        final notifier = container.read(
          partyCreateWizardControllerProvider.notifier,
        );

        notifier.nextStep();
        expect(
          container.read(partyCreateWizardControllerProvider).currentStep,
          PartyCreateStep.location,
        );
      });

      test('previousStep goes back', () {
        final container = makeContainer();
        final notifier = container.read(
          partyCreateWizardControllerProvider.notifier,
        );

        notifier.nextStep(); // -> location
        notifier.previousStep(); // -> basicInfo

        expect(
          container.read(partyCreateWizardControllerProvider).currentStep,
          PartyCreateStep.basicInfo,
        );
      });

      test('previousStep does nothing at first step', () {
        final container = makeContainer();
        final notifier = container.read(
          partyCreateWizardControllerProvider.notifier,
        );

        notifier.previousStep();

        expect(
          container.read(partyCreateWizardControllerProvider).currentStep,
          PartyCreateStep.basicInfo,
        );
      });

      test('nextStep does nothing at last step', () {
        final container = makeContainer();
        final notifier = container.read(
          partyCreateWizardControllerProvider.notifier,
        );

        // Navigate to last step
        for (var i = 0; i < PartyCreateStep.values.length - 1; i++) {
          notifier.nextStep();
        }

        expect(
          container.read(partyCreateWizardControllerProvider).currentStep,
          PartyCreateStep.review,
        );

        notifier.nextStep();

        expect(
          container.read(partyCreateWizardControllerProvider).currentStep,
          PartyCreateStep.review,
        );
      });

      test('setStep jumps to specific step', () {
        final container = makeContainer();
        final notifier = container.read(
          partyCreateWizardControllerProvider.notifier,
        );

        notifier.setStep(PartyCreateStep.tickets);

        expect(
          container.read(partyCreateWizardControllerProvider).currentStep,
          PartyCreateStep.tickets,
        );
      });
    });

    group('step 1: basic info', () {
      test('updateTitle updates state', () {
        final container = makeContainer();
        final notifier = container.read(
          partyCreateWizardControllerProvider.notifier,
        );

        notifier.updateTitle('My Party');

        expect(
          container.read(partyCreateWizardControllerProvider).title,
          'My Party',
        );
      });

      test('updateDescription updates state', () {
        final container = makeContainer();
        final notifier = container.read(
          partyCreateWizardControllerProvider.notifier,
        );

        final desc = {
          'ops': [
            {'insert': 'Hello\n'},
          ],
        };
        notifier.updateDescription(desc);

        expect(
          container.read(partyCreateWizardControllerProvider).description,
          desc,
        );
      });

      test('setVisibility updates state', () {
        final container = makeContainer();
        final notifier = container.read(
          partyCreateWizardControllerProvider.notifier,
        );

        notifier.setVisibility('private');

        expect(
          container.read(partyCreateWizardControllerProvider).visibility,
          'private',
        );
      });
    });

    group('step 2: location', () {
      test('updateLocation updates state', () {
        final container = makeContainer();
        final notifier = container.read(
          partyCreateWizardControllerProvider.notifier,
        );
        final now = DateTime.now();

        final location = Location(
          id: 'loc-1',
          partnerId: 'p-1',
          name: 'Test',
          address: '서울시',
          createdAt: now,
          updatedAt: now,
        );
        notifier.updateLocation(location);

        expect(
          container
              .read(partyCreateWizardControllerProvider)
              .selectedLocation
              ?.id,
          'loc-1',
        );
      });

      test('updateAddressDetail updates state', () {
        final container = makeContainer();
        final notifier = container.read(
          partyCreateWizardControllerProvider.notifier,
        );

        notifier.updateAddressDetail('2층');

        expect(
          container.read(partyCreateWizardControllerProvider).addressDetail,
          '2층',
        );
      });
    });

    group('step 3: capacity & contact', () {
      test('updateCapacity updates min count', () {
        final container = makeContainer();
        final notifier = container.read(
          partyCreateWizardControllerProvider.notifier,
        );

        notifier.updateCapacity(min: 10);

        expect(
          container.read(partyCreateWizardControllerProvider).minConfirmedCount,
          10,
        );
      });

      test('toggleContactMethod adds and removes methods', () {
        final container = makeContainer();
        final notifier = container.read(
          partyCreateWizardControllerProvider.notifier,
        );

        notifier.toggleContactMethod('phone');
        expect(
          container
              .read(partyCreateWizardControllerProvider)
              .enabledContactMethods,
          contains('phone'),
        );

        notifier.toggleContactMethod('phone');
        expect(
          container
              .read(partyCreateWizardControllerProvider)
              .enabledContactMethods,
          isNot(contains('phone')),
        );
      });

      test('toggleBalance flips balanceEnabled', () {
        final container = makeContainer();
        final notifier = container.read(
          partyCreateWizardControllerProvider.notifier,
        );

        expect(
          container.read(partyCreateWizardControllerProvider).balanceEnabled,
          isFalse,
        );

        notifier.toggleBalance();

        expect(
          container.read(partyCreateWizardControllerProvider).balanceEnabled,
          isTrue,
        );
      });
    });

    group('step 4: entry groups', () {
      test('addEntryGroup appends group', () {
        final container = makeContainer();
        final notifier = container.read(
          partyCreateWizardControllerProvider.notifier,
        );

        const group = EntryGroupTemplate(
          id: 'eg-1',
          partyId: '',
          gender: 'male',
        );
        notifier.addEntryGroup(group);

        expect(
          container.read(partyCreateWizardControllerProvider).entryGroups,
          hasLength(1),
        );
      });

      test('removeEntryGroup removes by id', () {
        final container = makeContainer();
        final notifier = container.read(
          partyCreateWizardControllerProvider.notifier,
        );

        const group1 = EntryGroupTemplate(id: 'eg-1', partyId: '');
        const group2 = EntryGroupTemplate(id: 'eg-2', partyId: '');
        notifier.addEntryGroup(group1);
        notifier.addEntryGroup(group2);

        notifier.removeEntryGroup('eg-1');

        final groups = container
            .read(partyCreateWizardControllerProvider)
            .entryGroups;
        expect(groups, hasLength(1));
        expect(groups.first.id, 'eg-2');
      });

      test('updateEntryGroup replaces matching group', () {
        final container = makeContainer();
        final notifier = container.read(
          partyCreateWizardControllerProvider.notifier,
        );

        const group = EntryGroupTemplate(id: 'eg-1', partyId: '');
        notifier.addEntryGroup(group);

        const updated = EntryGroupTemplate(
          id: 'eg-1',
          partyId: '',
          gender: 'female',
        );
        notifier.updateEntryGroup(updated);

        final groups = container
            .read(partyCreateWizardControllerProvider)
            .entryGroups;
        expect(groups.first.gender, 'female');
      });
    });

    // Fix #1743: loadForEdit이 entry_group_templates와 ticket_templates를 올바르게 로드하는지 검증.
    // 수정 위저드 진입 시 Step4(입장규칙)/Step5(티켓)에 기존 데이터가 pre-fill 되어야 함.
    group('loadForEdit', () {
      test(
        'pre-fills entryGroups and tickets from existing party data',
        () async {
          final now = DateTime.now();
          const partyId = 'party-edit-1';

          final entryGroups = [
            EntryGroupTemplate(
              id: 'eg-1',
              partyId: partyId,
              gender: 'male',
              birthYearMin: 1995,
              birthYearMax: 2004,
              createdAt: now,
              updatedAt: now,
            ),
            EntryGroupTemplate(
              id: 'eg-2',
              partyId: partyId,
              gender: 'female',
              birthYearMin: 1995,
              birthYearMax: 2004,
              createdAt: now,
              updatedAt: now,
            ),
          ];

          final ticketTemplates = [
            TicketTemplate(
              id: 'tt-1',
              partyId: partyId,
              name: '일반 참가권',
              quantity: 20,
              createdAt: now,
              updatedAt: now,
            ),
          ];

          final party = Party(
            id: partyId,
            partnerId: 'partner-1',
            title: '테스트 파티',
            maxParticipants: 40,
            entryGroups: entryGroups,
            createdAt: now,
            updatedAt: now,
          );

          when(
            () => mockPartyRepo.getPartyById(partyId),
          ).thenAnswer((_) async => party);
          when(
            () => mockTicketRepo.getTicketTemplatesByPartyId(partyId),
          ).thenAnswer((_) async => ticketTemplates);
          when(
            () => mockTagRepo.getTagsByPartyId(partyId),
          ).thenAnswer((_) async => []);

          final container = makeContainer();
          final notifier = container.read(
            partyCreateWizardControllerProvider.notifier,
          );

          await notifier.loadForEdit(partyId);

          final state = container.read(partyCreateWizardControllerProvider);
          // Fix #1743: Step4 — 기존 입장 그룹이 로드되어야 함
          expect(state.entryGroups, hasLength(2));
          expect(state.entryGroups.first.id, 'eg-1');
          expect(state.entryGroups.last.id, 'eg-2');
          // Fix #1743: Step5 — 기존 티켓 템플릿이 로드되어야 함
          expect(state.tickets, hasLength(1));
          expect(state.tickets.first.id, 'tt-1');
          expect(state.isPrefilled, isTrue);
        },
      );

      test(
        'pre-fills empty lists when party has no entry groups or tickets',
        () async {
          final now = DateTime.now();
          const partyId = 'party-empty-1';

          final party = Party(
            id: partyId,
            partnerId: 'partner-1',
            title: '빈 파티',
            createdAt: now,
            updatedAt: now,
          );

          when(
            () => mockPartyRepo.getPartyById(partyId),
          ).thenAnswer((_) async => party);
          when(
            () => mockTicketRepo.getTicketTemplatesByPartyId(partyId),
          ).thenAnswer((_) async => []);
          when(
            () => mockTagRepo.getTagsByPartyId(partyId),
          ).thenAnswer((_) async => []);

          final container = makeContainer();
          final notifier = container.read(
            partyCreateWizardControllerProvider.notifier,
          );

          await notifier.loadForEdit(partyId);

          final state = container.read(partyCreateWizardControllerProvider);
          expect(state.entryGroups, isEmpty);
          expect(state.tickets, isEmpty);
          expect(state.isPrefilled, isTrue);
        },
      );
    });

    group('submit', () {
      test('submit with validation errors sets error status', () async {
        final container = makeContainer();
        final notifier = container.read(
          partyCreateWizardControllerProvider.notifier,
        );

        // State is empty — validation should fail
        await notifier.submit();

        final state = container.read(partyCreateWizardControllerProvider);
        expect(state.status, isA<AsyncError<void>>());
      });

      test('submit success creates party and tickets', () async {
        final now = DateTime.now();
        final location = Location(
          id: 'loc-1',
          partnerId: 'partner-1',
          name: 'Test',
          address: '서울시',
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockPartnerRepo.getMyManagedPartners()).thenAnswer(
          (_) async => [const Partner(id: 'partner-1', name: 'Test')],
        );
        when(() => mockLocationRepo.createLocation(any())).thenAnswer(
          (_) async => location,
        );

        final createdParty = Party(
          id: 'new-party-1',
          partnerId: 'partner-1',
          title: 'Test Party',
          createdAt: now,
          updatedAt: now,
        );
        when(
          () => mockPartyRepo.createParty(
            any(),
            extraFields: any(named: 'extraFields'),
          ),
        ).thenAnswer((_) async => createdParty);
        when(
          () => mockPartyRepo.uploadPartyImages(any(), any()),
        ).thenAnswer((_) async => []);

        final ticketTemplate = TicketTemplate(
          id: 't-1',
          partyId: 'new-party-1',
          name: 'Standard',
          createdAt: now,
          updatedAt: now,
        );
        when(
          () => mockTicketRepo.createTicketTemplate(any()),
        ).thenAnswer((_) async => ticketTemplate);

        final container = makeContainer();
        final notifier = container.read(
          partyCreateWizardControllerProvider.notifier,
        );

        // Fill required state
        notifier.updateTitle('Test Party');
        notifier.updateDescription({
          'ops': [
            {'insert': 'Description\n'},
          ],
        });
        notifier.updateLocation(location);
        notifier.toggleContactMethod('phone');
        notifier.updateContactPhone('010-1234-5678');
        notifier.addEntryGroup(
          const EntryGroupTemplate(id: 'eg-1', partyId: ''),
        );
        notifier.updateCapacity(min: 1);
        notifier.addTicket(
          TicketTemplate(
            id: '',
            partyId: '',
            name: 'Standard',
            createdAt: now,
            updatedAt: now,
            quantity: 10,
          ),
        );

        await notifier.submit();

        final state = container.read(partyCreateWizardControllerProvider);
        expect(state.status, isA<AsyncData<void>>());
        verify(
          () => mockPartyRepo.createParty(
            any(),
            extraFields: any(named: 'extraFields'),
          ),
        ).called(1);
      });
    });
  });
}
