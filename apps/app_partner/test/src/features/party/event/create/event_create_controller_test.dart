import 'package:app_partner/src/features/party/event/create/event_create_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../utils/mocks.dart';
import '../../../../../utils/test_utils.dart';

Future<void> pump() async {
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

void main() {
  late MockPartyRepository mockPartyRepo;

  setUp(() {
    mockPartyRepo = MockPartyRepository();
  });

  ProviderContainer makeContainer() {
    return createContainer(
      overrides: [
        partyRepositoryProvider.overrideWithValue(mockPartyRepo),
      ],
    );
  }

  group('EventCreateController - initial state', () {
    test('build initialises state with provided partyId', () {
      final container = makeContainer();
      final state =
          container.read(eventCreateControllerProvider('party-1'));

      expect(state.partyId, 'party-1');
      expect(state.maxParticipants, 20);
      expect(state.title, '');
      expect(state.status, isA<AsyncData<void>>());
    });

    test('startTime is in the future and endTime is 3 hours after startTime',
        () {
      final container = makeContainer();
      final state =
          container.read(eventCreateControllerProvider('party-1'));

      expect(state.startTime.isAfter(DateTime.now()), isTrue);
      expect(
        state.endTime.difference(state.startTime),
        const Duration(hours: 3),
      );
    });
  });

  group('EventCreateController - field updates', () {
    test('updateTitle changes title', () {
      final container = makeContainer();
      container
          .read(eventCreateControllerProvider('party-1').notifier)
          .updateTitle('New Title');

      final state = container.read(eventCreateControllerProvider('party-1'));
      expect(state.title, 'New Title');
    });

    test('updateMaxParticipants changes maxParticipants', () {
      final container = makeContainer();
      container
          .read(eventCreateControllerProvider('party-1').notifier)
          .updateMaxParticipants(50);

      final state = container.read(eventCreateControllerProvider('party-1'));
      expect(state.maxParticipants, 50);
    });

    test('updateStartTime adjusts endTime when endTime is before new startTime',
        () {
      final container = makeContainer();
      final notifier =
          container.read(eventCreateControllerProvider('party-1').notifier);

      final futureStart = DateTime.now().add(const Duration(days: 30));
      // First push endTime behind the new start by setting an earlier start
      notifier.updateEndTime(futureStart.subtract(const Duration(hours: 1)));
      notifier.updateStartTime(futureStart);

      final state = container.read(eventCreateControllerProvider('party-1'));
      expect(state.endTime.isAfter(state.startTime), isTrue);
      expect(
        state.endTime.difference(state.startTime),
        const Duration(hours: 3),
      );
    });

    test('setVisibility updates visibility', () {
      final container = makeContainer();
      container
          .read(eventCreateControllerProvider('party-1').notifier)
          .setVisibility('private');

      final state = container.read(eventCreateControllerProvider('party-1'));
      expect(state.visibility, 'private');
    });
  });
}
