import 'package:app_user/src/features/event/logic/event_my_application_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

class MockUser extends Mock implements User {}

void main() {
  late MockEventRepository mockEventRepo;
  late MockUser mockUser;

  setUp(() {
    mockEventRepo = MockEventRepository();
    mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user_123');
  });

  group('eventMyApplicationProvider', () {
    test('returns null when user is not logged in', () async {
      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWithValue(null),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
        ],
      );

      final result = await container.read(
        eventMyApplicationProvider('event_abc').future,
      );

      expect(result, isNull);
      verifyNever(
        () => mockEventRepo.getApplication(
          eventId: any(named: 'eventId'),
          userId: any(named: 'userId'),
        ),
      );
    });

    test(
      'returns application when user is logged in and application exists',
      () async {
        final mockApplication = EventApplication(
          id: 'app_1',
          eventId: 'event_abc',
          ticketId: 'ticket_1',
          userId: 'user_123',
          status: 'approved',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(
          () => mockEventRepo.getApplication(
            eventId: 'event_abc',
            userId: 'user_123',
          ),
        ).thenAnswer((_) async => mockApplication);

        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWithValue(mockUser),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          ],
        );

        final result = await container.read(
          eventMyApplicationProvider('event_abc').future,
        );

        expect(result, mockApplication);
      },
    );

    test(
      'returns null when user is logged in but no application found',
      () async {
        when(
          () => mockEventRepo.getApplication(
            eventId: 'event_abc',
            userId: 'user_123',
          ),
        ).thenAnswer((_) async => null);

        final container = createContainer(
          overrides: [
            currentUserProvider.overrideWithValue(mockUser),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          ],
        );

        final result = await container.read(
          eventMyApplicationProvider('event_abc').future,
        );

        expect(result, isNull);
      },
    );

    test('calls repository with correct eventId and userId', () async {
      when(
        () => mockEventRepo.getApplication(
          eventId: 'event_abc',
          userId: 'user_123',
        ),
      ).thenAnswer((_) async => null);

      final container = createContainer(
        overrides: [
          currentUserProvider.overrideWithValue(mockUser),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
        ],
      );

      await container.read(eventMyApplicationProvider('event_abc').future);

      verify(
        () => mockEventRepo.getApplication(
          eventId: 'event_abc',
          userId: 'user_123',
        ),
      ).called(1);
    });
  });
}
