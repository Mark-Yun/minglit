// Critical-path tests for EventCreateController.submit with recurrence enabled.
//
// When recurrenceSettingsControllerProvider.isEnabled is true, submit must call
// recurrenceRuleRepository.create() in addition to partyRepository.createEvent().
// A regression here would create an event without its recurrence rule — partner
// thinks recurrence is set up, but it silently never generates future events.
//
// Also tests the recurrence-disabled path to ensure create() is NOT called when
// the feature is off (guards against false-positive rule creation).

import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/event/create/event_create_controller.dart';
import 'package:app_partner/src/features/party/logic/recurrence_settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../utils/mocks.dart';
import '../../../../../utils/test_utils.dart';

// ---------------------------------------------------------------------------
// Local mock — RecurrenceRuleRepository is concrete, not abstract
// ---------------------------------------------------------------------------

class _MockRecurrenceRuleRepository extends Mock
    implements RecurrenceRuleRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Party _makeParty({String id = 'party-rec-1'}) {
  final now = DateTime.now();
  return Party(
    id: id,
    partnerId: 'partner-1',
    title: 'Test Party',
    locationId: 'loc-1',
    createdAt: now,
    updatedAt: now,
  );
}

Event _makeEvent({String id = 'event-rec-1'}) {
  final now = DateTime.now();
  return Event(
    id: id,
    partyId: 'party-rec-1',
    startTime: now.add(const Duration(days: 7)),
    endTime: now.add(const Duration(days: 7, hours: 3)),
    createdAt: now,
    updatedAt: now,
  );
}

RecurrenceRule _makeRule() {
  final now = DateTime.now();
  return RecurrenceRule(
    id: 'rule-1',
    partyId: 'party-rec-1',
    pattern: RecurrencePattern.weekly,
    startTime: '19:00',
    endTime: '22:00',
    createdAt: now,
    updatedAt: now,
    daysOfWeek: [6],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockPartyRepository mockPartyRepo;
  late MockLocationRepository mockLocationRepo;
  late _MockRecurrenceRuleRepository mockRecurrenceRepo;

  setUp(() {
    mockPartyRepo = MockPartyRepository();
    mockLocationRepo = MockLocationRepository();
    mockRecurrenceRepo = _MockRecurrenceRuleRepository();
  });

  setUpAll(() {
    registerFallbackValue(
      Event(
        id: '',
        partyId: '',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    registerFallbackValue(RecurrencePattern.weekly);
  });

  group('EventCreateController.submit — recurrence enabled', () {
    test(
      'calls recurrenceRuleRepository.create() when isEnabled is true',
      () async {
        final party = _makeParty();

        when(() => mockPartyRepo.createEvent(any())).thenAnswer(
          (_) async => _makeEvent(),
        );
        when(
          () => mockRecurrenceRepo.create(
            partyId: any(named: 'partyId'),
            pattern: any(named: 'pattern'),
            daysOfWeek: any(named: 'daysOfWeek'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            monthDay: any(named: 'monthDay'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => _makeRule());

        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
            locationRepositoryProvider.overrideWithValue(mockLocationRepo),
            recurrenceRuleRepositoryProvider.overrideWithValue(
              mockRecurrenceRepo,
            ),
            partyDetailProvider('party-rec-1').overrideWith(
              (ref) async => party,
            ),
            // Enable recurrence in the settings controller
            recurrenceSettingsControllerProvider.overrideWith(
              () {
                final controller = RecurrenceSettingsController();
                // We need to override build to return enabled state
                return controller;
              },
            ),
          ],
        );

        // Enable recurrence
        container
            .read(recurrenceSettingsControllerProvider.notifier)
            .toggle(); // isEnabled: false → true
        container
            .read(recurrenceSettingsControllerProvider.notifier)
            .toggleDay(6); // Saturday

        final notifier = container.read(
          eventCreateControllerProvider('party-rec-1').notifier,
        );
        notifier.updateLocation(
          Location(
            id: 'loc-1',
            partnerId: 'partner-1',
            name: 'Venue',
            address: '서울시',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await notifier.submit();

        final state = container.read(
          eventCreateControllerProvider('party-rec-1'),
        );
        expect(state.status, isA<AsyncData<void>>());

        verify(() => mockPartyRepo.createEvent(any())).called(1);
        verify(
          () => mockRecurrenceRepo.create(
            partyId: any(named: 'partyId'),
            pattern: any(named: 'pattern'),
            daysOfWeek: any(named: 'daysOfWeek'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            monthDay: any(named: 'monthDay'),
            endDate: any(named: 'endDate'),
          ),
        ).called(1);
      },
    );

    test(
      'formats startTime and endTime as HH:MM when calling create()',
      () async {
        final party = _makeParty();
        final now = DateTime.now();
        // Fix specific times so we can assert the exact formatted strings
        final startTime = DateTime(now.year, now.month, now.day + 7, 19, 30);
        final endTime = DateTime(now.year, now.month, now.day + 7, 22, 0);

        when(() => mockPartyRepo.createEvent(any())).thenAnswer(
          (_) async => _makeEvent(),
        );
        when(
          () => mockRecurrenceRepo.create(
            partyId: any(named: 'partyId'),
            pattern: any(named: 'pattern'),
            daysOfWeek: any(named: 'daysOfWeek'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            monthDay: any(named: 'monthDay'),
            endDate: any(named: 'endDate'),
          ),
        ).thenAnswer((_) async => _makeRule());

        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
            locationRepositoryProvider.overrideWithValue(mockLocationRepo),
            recurrenceRuleRepositoryProvider.overrideWithValue(
              mockRecurrenceRepo,
            ),
            partyDetailProvider('party-rec-1').overrideWith(
              (ref) async => party,
            ),
          ],
        );

        container
            .read(recurrenceSettingsControllerProvider.notifier)
            .toggle(); // enable

        final notifier = container.read(
          eventCreateControllerProvider('party-rec-1').notifier,
        );
        notifier.updateStartTime(startTime);
        notifier.updateEndTime(endTime);
        notifier.updateLocation(
          Location(
            id: 'loc-1',
            partnerId: 'partner-1',
            name: 'Venue',
            address: '서울시',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await notifier.submit();

        // Capture the create() call arguments
        final createCall = verify(
          () => mockRecurrenceRepo.create(
            partyId: captureAny(named: 'partyId'),
            pattern: captureAny(named: 'pattern'),
            daysOfWeek: captureAny(named: 'daysOfWeek'),
            startTime: captureAny(named: 'startTime'),
            endTime: captureAny(named: 'endTime'),
            monthDay: captureAny(named: 'monthDay'),
            endDate: captureAny(named: 'endDate'),
          ),
        )..called(1);

        // captureAny with named returns a list of [partyId, pattern, daysOfWeek, startTime, endTime, ...]
        final captured = createCall.captured;
        // The captured values for named params come in the order they appear in verify()
        final capturedStartTime = captured[3] as String; // 'startTime' index
        final capturedEndTime = captured[4] as String;   // 'endTime' index

        // HH:MM format — must be zero-padded
        expect(capturedStartTime, '19:30');
        expect(capturedEndTime, '22:00');
      },
    );
  });

  group('EventCreateController.submit — recurrence disabled', () {
    test(
      'does NOT call recurrenceRuleRepository.create() when isEnabled is false',
      () async {
        final party = _makeParty();

        when(() => mockPartyRepo.createEvent(any())).thenAnswer(
          (_) async => _makeEvent(),
        );

        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
            locationRepositoryProvider.overrideWithValue(mockLocationRepo),
            recurrenceRuleRepositoryProvider.overrideWithValue(
              mockRecurrenceRepo,
            ),
            partyDetailProvider('party-rec-1').overrideWith(
              (ref) async => party,
            ),
            // isEnabled defaults to false — no toggle() call
          ],
        );

        final notifier = container.read(
          eventCreateControllerProvider('party-rec-1').notifier,
        );
        notifier.updateLocation(
          Location(
            id: 'loc-1',
            partnerId: 'partner-1',
            name: 'Venue',
            address: '서울시',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await notifier.submit();

        final state = container.read(
          eventCreateControllerProvider('party-rec-1'),
        );
        expect(state.status, isA<AsyncData<void>>());
        verify(() => mockPartyRepo.createEvent(any())).called(1);
        // Recurrence must NOT be created when disabled
        verifyNever(
          () => mockRecurrenceRepo.create(
            partyId: any(named: 'partyId'),
            pattern: any(named: 'pattern'),
            daysOfWeek: any(named: 'daysOfWeek'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          ),
        );
      },
    );
  });

  group('EventCreateController.submit — recurrence create() failure', () {
    test(
      'sets AsyncError when recurrenceRuleRepository.create() throws',
      () async {
        final party = _makeParty();

        when(() => mockPartyRepo.createEvent(any())).thenAnswer(
          (_) async => _makeEvent(),
        );
        when(
          () => mockRecurrenceRepo.create(
            partyId: any(named: 'partyId'),
            pattern: any(named: 'pattern'),
            daysOfWeek: any(named: 'daysOfWeek'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            monthDay: any(named: 'monthDay'),
            endDate: any(named: 'endDate'),
          ),
        ).thenThrow(Exception('Edge Function error'));

        final container = createContainer(
          overrides: [
            partyRepositoryProvider.overrideWithValue(mockPartyRepo),
            locationRepositoryProvider.overrideWithValue(mockLocationRepo),
            recurrenceRuleRepositoryProvider.overrideWithValue(
              mockRecurrenceRepo,
            ),
            partyDetailProvider('party-rec-1').overrideWith(
              (ref) async => party,
            ),
          ],
        );

        container.read(recurrenceSettingsControllerProvider.notifier).toggle();

        final notifier = container.read(
          eventCreateControllerProvider('party-rec-1').notifier,
        );
        notifier.updateLocation(
          Location(
            id: 'loc-1',
            partnerId: 'partner-1',
            name: 'Venue',
            address: '서울시',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        await notifier.submit();

        final state = container.read(
          eventCreateControllerProvider('party-rec-1'),
        );
        expect(state.status, isA<AsyncError<void>>());
      },
    );
  });
}
