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

EventApplication _makeApplication(
  String id, {
  String status = 'approved',
  DateTime? createdAt,
  Ticket? ticket,
}) {
  final now = createdAt ?? DateTime(2026, 5, 10, 20);
  return EventApplication(
    id: id,
    eventId: 'event_1',
    ticketId: 'ticket_1',
    userId: 'user_$id',
    status: status,
    createdAt: now,
    updatedAt: now,
    ticket: ticket,
  );
}

Ticket _makeTicket(String id, List<String> groupIds) {
  final now = DateTime(2026, 5, 10);
  return Ticket(
    id: id,
    name: 'Ticket $id',
    createdAt: now,
    updatedAt: now,
    targetEntryGroupIds: groupIds,
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

    test('returns applications with matching mock', () async {
      final event = _makeEvent('event_1');
      final applications = [_makeApplication('app_1')];
      when(
        () => mockRepo.getEventById('event_1'),
      ).thenAnswer((_) async => event);
      when(
        () => mockRepo.getApplicationsByEventId('event_1'),
      ).thenAnswer((_) async => applications);
      when(
        () => mockRepo.getEntryGroupParticipantCounts('event_1'),
      ).thenAnswer((_) async => []);
      final container = createContainer(
        overrides: [eventRepositoryProvider.overrideWithValue(mockRepo)],
      );
      final result = await container.read(
        eventApplicationBundleProvider('event_1').future,
      );
      expect(result.applications, same(applications));
    });

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

      // In Riverpod 3, @riverpod async providers auto-retry on error.
      // The state transitions to AsyncLoading(hasError=true) rather than
      // AsyncError. Use listen to keep the provider alive, then check
      // hasError on the AsyncLoading state.
      final sub = container.listen(
        eventApplicationBundleProvider('event_err'),
        (_, _) {},
      );
      addTearDown(sub.close);
      await Future<void>.delayed(Duration.zero);
      final state = container.read(eventApplicationBundleProvider('event_err'));
      expect(state.hasError, isTrue);
      expect(state.error, isA<Exception>());
    });
  });

  // Fix #2127: carouselQueueProvider — groupId-based filtering
  group('carouselQueueProvider', () {
    final ticketFemale = _makeTicket('t_f', ['eg_female']);
    final ticketMale = _makeTicket('t_m', ['eg_male']);

    late List<EventApplication> allApplications;

    setUp(() {
      allApplications = [
        _makeApplication(
          'a1',
          status: 'pending',
          createdAt: DateTime(2026, 5, 10, 9),
          ticket: ticketFemale,
        ),
        _makeApplication(
          'a2',
          status: 'pending_review',
          createdAt: DateTime(2026, 5, 10, 10),
          ticket: ticketMale,
        ),
        _makeApplication(
          'a3',
          status: 'approved',
          createdAt: DateTime(2026, 5, 10, 8),
          ticket: ticketFemale,
        ),
        _makeApplication(
          'a4',
          status: 'pending',
          createdAt: DateTime(2026, 5, 10, 11),
          ticket: ticketFemale,
        ),
      ];
      when(
        () => mockRepo.getApplicationsByEventId('event_1'),
      ).thenAnswer((_) async => allApplications);
    });

    test('returns all pending applications sorted by createdAt ASC '
        'when groupId is null', () async {
      final container = createContainer(
        overrides: [eventRepositoryProvider.overrideWithValue(mockRepo)],
      );
      final result = await container.read(
        carouselQueueProvider('event_1', null).future,
      );
      // a3 is 'approved' → excluded. a1, a2, a4 are pending/pending_review.
      expect(result.map((a) => a.id), orderedEquals(['a1', 'a2', 'a4']));
    });

    test('filters by groupId and excludes non-pending statuses', () async {
      final container = createContainer(
        overrides: [eventRepositoryProvider.overrideWithValue(mockRepo)],
      );
      final result = await container.read(
        carouselQueueProvider('event_1', 'eg_female').future,
      );
      // a1 (pending, female), a4 (pending, female) match.
      // a3 (approved) excluded even though female ticket.
      // a2 (male ticket) excluded.
      expect(result.map((a) => a.id), orderedEquals(['a1', 'a4']));
    });

    test(
      'returns empty list when no pending applications match groupId',
      () async {
        final container = createContainer(
          overrides: [eventRepositoryProvider.overrideWithValue(mockRepo)],
        );
        final result = await container.read(
          carouselQueueProvider('event_1', 'eg_unknown').future,
        );
        expect(result, isEmpty);
      },
    );

    test('revert check: removing groupId filter includes all pending '
        'statuses', () async {
      final container = createContainer(
        overrides: [eventRepositoryProvider.overrideWithValue(mockRepo)],
      );
      final withGroup = await container.read(
        carouselQueueProvider('event_1', 'eg_male').future,
      );
      final withoutGroup = await container.read(
        carouselQueueProvider('event_1', null).future,
      );
      // groupId=eg_male only has a2; null groupId has a1,a2,a4
      expect(withGroup.map((a) => a.id), ['a2']);
      expect(withoutGroup, hasLength(3));
    });
  });
}
