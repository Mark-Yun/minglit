import 'package:app_user/src/features/home/widgets/event_now_bar_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

void main() {
  late MockEventRepository mockEventRepo;
  late MockUser mockUser;

  setUp(() {
    mockEventRepo = MockEventRepository();
    mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user_123');
  });

  TodayActiveEvent makeActiveEvent({
    String id = 'event_1',
    String status = 'scheduled',
    String participantStatus = 'ticket_issued',
    DateTime? startTime,
    DateTime? endTime,
  }) {
    final now = DateTime.now();
    return TodayActiveEvent(
      event: Event(
        id: id,
        partyId: 'party_1',
        startTime: startTime ?? now.subtract(const Duration(hours: 1)),
        endTime: endTime ?? now.add(const Duration(hours: 2)),
        createdAt: now,
        updatedAt: now,
        status: status,
      ),
      participantStatus: participantStatus,
    );
  }

  group('todayActiveEventsProvider', () {
    test('returns empty list when user is not logged in', () async {
      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWithValue(null),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
        ],
      );

      final result = await container.read(
        todayActiveEventsProvider.future,
      );

      expect(result, isEmpty);
      verifyNever(
        () => mockEventRepo.getTodayActiveEventsForUser(
          any(),
        ),
      );
    });

    test('returns active events when user is logged in (happy path)', () async {
      final activeEvents = [
        makeActiveEvent(),
        makeActiveEvent(id: 'event_2', participantStatus: 'checked_in'),
      ];

      when(
        () => mockEventRepo.getTodayActiveEventsForUser('user_123'),
      ).thenAnswer((_) async => activeEvents);

      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWithValue(mockUser),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
        ],
      );

      final result = await container.read(
        todayActiveEventsProvider.future,
      );

      expect(result, hasLength(2));
      expect(result[0].event.id, 'event_1');
      expect(result[0].participantStatus, 'ticket_issued');
      expect(result[1].event.id, 'event_2');
      expect(result[1].participantStatus, 'checked_in');
    });

    test('returns empty list when no active events (0건)', () async {
      when(
        () => mockEventRepo.getTodayActiveEventsForUser('user_123'),
      ).thenAnswer((_) async => []);

      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWithValue(mockUser),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
        ],
      );

      final result = await container.read(
        todayActiveEventsProvider.future,
      );

      expect(result, isEmpty);
    });

    test('includes cancelled events', () async {
      final activeEvents = [
        makeActiveEvent(status: 'cancelled'),
      ];

      when(
        () => mockEventRepo.getTodayActiveEventsForUser('user_123'),
      ).thenAnswer((_) async => activeEvents);

      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWithValue(mockUser),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
        ],
      );

      final result = await container.read(
        todayActiveEventsProvider.future,
      );

      expect(result, hasLength(1));
      expect(result.first.event.status, 'cancelled');
    });

    test('includes events crossing midnight (endTime-based)', () async {
      final now = DateTime.now();
      final activeEvents = [
        makeActiveEvent(
          id: 'midnight_event',
          startTime: DateTime(now.year, now.month, now.day - 1, 22), // 어제 22시
          endTime: DateTime(now.year, now.month, now.day, 2), // 오늘 02시
        ),
      ];

      when(
        () => mockEventRepo.getTodayActiveEventsForUser('user_123'),
      ).thenAnswer((_) async => activeEvents);

      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWithValue(mockUser),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
        ],
      );

      final result = await container.read(
        todayActiveEventsProvider.future,
      );

      expect(result, hasLength(1));
      expect(result.first.event.id, 'midnight_event');
    });

    test('propagates repository errors', () async {
      when(
        () => mockEventRepo.getTodayActiveEventsForUser('user_123'),
      ).thenThrow(Exception('Network error'));

      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWithValue(mockUser),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
        ],
      );

      final sub = container.listen(
        todayActiveEventsProvider,
        (_, _) {},
      );

      // Wait for the provider to settle
      await Future<void>.delayed(Duration.zero);

      final state = sub.read();
      expect(state.hasError, isTrue);
      expect(state.error, isA<Exception>());
    });
  });
}
