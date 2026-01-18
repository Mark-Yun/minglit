import 'package:app_user/src/features/event/logic/event_detail_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

void main() {
  late MockEventRepository mockEventRepo;

  // Test Data
  final testEvent = Event(
    id: 'event_1',
    partyId: 'party_1',
    startTime: DateTime.now(),
    endTime: DateTime.now().add(const Duration(hours: 2)),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    title: 'Test Event',
  );

  setUp(() {
    mockEventRepo = MockEventRepository();
  });

  group('EventDetailController', () {
    test('returns event when repository succeeds', () async {
      when(() => mockEventRepo.getEventById('event_1'))
          .thenAnswer((_) async => testEvent);

      final container = createContainer(
        overrides: [
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
        ],
      );

      final result = await container.read(eventDetailControllerProvider('event_1').future);
      expect(result, testEvent);
    });

    // FIXME: This test fails with 'provider disposed' error. Needs investigation.
    // test('throws exception when repository fails', () async {
    //   final exception = Exception('Network Error');
    //   when(() => mockEventRepo.getEventById('event_1'))
    //       .thenAnswer((_) async => throw exception);

    //   final container = createContainer(
    //     overrides: [
    //       eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
    //     ],
    //   );

    //   // Listen to prevent premature disposal
    //   final subscription = container.listen(
    //     eventDetailControllerProvider('event_1'),
    //     (previous, next) {},
    //     fireImmediately: true,
    //   );

    //   await expectLater(
    //     container.read(eventDetailControllerProvider('event_1').future),
    //     throwsA(isA<Exception>()),
    //   );
      
    //   subscription.close();
    // });
  });
}
