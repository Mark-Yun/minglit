import 'package:app_partner/src/logic/event_application_logic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../utils/mocks.dart';
import '../../../../../utils/test_utils.dart';

Event _makeEvent(String id) {
  final now = DateTime(2026, 5, 10, 20);
  return Event(
    id: id,
    partyId: 'party_1',
    title: '스피드 데이팅',
    startTime: now.add(const Duration(hours: 2)),
    endTime: now.add(const Duration(hours: 4)),
    createdAt: now,
    updatedAt: now,
    maxParticipants: 20,
    currentParticipants: 5,
    entryGroups: const [
      EntryGroup(
        id: 'eg_female',
        eventId: 'event_1',
        label: '여성 그룹',
        gender: 'female',
      ),
    ],
  );
}

EventApplication _makeApplication(String id) {
  final now = DateTime(2026, 5, 10, 20);
  return EventApplication(
    id: id,
    eventId: 'event_1',
    ticketId: 'ticket_1',
    userId: 'user_$id',
    status: 'approved',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late MockEventRepository mockRepo;

  setUp(() {
    mockRepo = MockEventRepository();
  });

  group('eventApplicationBundleProvider', () {
    test(
      'returns event applications and entry group data on success',
      () async {
        final event = _makeEvent('event_1');
        final applications = [
          _makeApplication('app_1'),
          _makeApplication('app_2'),
        ];
        final groupCounts = [
          {
            'entry_group_id': 'eg_female',
            'participant_count': 3,
            'target_capacity': 10,
          },
        ];

        when(
          () => mockRepo.getEventById('event_1'),
        ).thenAnswer((_) async => event);
        when(
          () => mockRepo.getApplicationsByEventId('event_1'),
        ).thenAnswer((_) async => applications);
        when(
          () => mockRepo.getEntryGroupParticipantCounts('event_1'),
        ).thenAnswer((_) async => groupCounts);

        final container = createContainer(
          overrides: [eventRepositoryProvider.overrideWithValue(mockRepo)],
        );

        final result = await container.read(
          eventApplicationBundleProvider('event_1').future,
        );

        expect(result.event, same(event));
        expect(result.applications, same(applications));
        expect(result.groupCounts, same(groupCounts));
        expect(result.event.entryGroups, hasLength(1));
        verify(() => mockRepo.getEventById('event_1')).called(1);
        verify(() => mockRepo.getApplicationsByEventId('event_1')).called(1);
        verify(
          () => mockRepo.getEntryGroupParticipantCounts('event_1'),
        ).called(1);
      },
    );

    test('emits AsyncError when getEventById throws', () async {
      when(
        () => mockRepo.getEventById('event_err'),
      ).thenAnswer((_) async => throw Exception('DB error'));
      when(
        () => mockRepo.getApplicationsByEventId('event_err'),
      ).thenAnswer((_) async => <EventApplication>[]);
      when(
        () => mockRepo.getEntryGroupParticipantCounts('event_err'),
      ).thenAnswer((_) async => <Map<String, dynamic>>[]);

      final container = createContainer(
        overrides: [eventRepositoryProvider.overrideWithValue(mockRepo)],
      );

      final sub = container.listen(
        eventApplicationBundleProvider('event_err'),
        (_, _) {},
      );
      addTearDown(sub.close);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(eventApplicationBundleProvider('event_err'));
      expect(state, isA<AsyncError<EventApplicationBundle>>());
    });
  });
}
