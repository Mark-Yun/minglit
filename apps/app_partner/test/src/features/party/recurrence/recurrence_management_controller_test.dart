import 'package:app_partner/src/features/party/recurrence/recurrence_management_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

class _MockRecurrenceRuleRepository extends Mock
    implements RecurrenceRuleRepository {}

void main() {
  late _MockRecurrenceRuleRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = _MockRecurrenceRuleRepository();
    container = ProviderContainer(
      overrides: [
        recurrenceRuleRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);
  });

  group('RecurrenceManagementController', () {
    test('pause — success transitions state to AsyncData', () async {
      when(() => mockRepo.pause(any())).thenAnswer((_) async {});

      final notifier = container.read(
        recurrenceManagementControllerProvider.notifier,
      );
      await notifier.pause('rule-1');

      final state = container.read(recurrenceManagementControllerProvider);
      expect(state, isA<AsyncData<void>>());
    });

    test('pause — error transitions state to AsyncError', () async {
      when(() => mockRepo.pause(any())).thenThrow(Exception('network error'));

      final notifier = container.read(
        recurrenceManagementControllerProvider.notifier,
      );
      await notifier.pause('rule-1');

      final state = container.read(recurrenceManagementControllerProvider);
      expect(state, isA<AsyncError<void>>());
    });

    test('resume — success transitions state to AsyncData', () async {
      when(() => mockRepo.resume(any())).thenAnswer((_) async {});

      final notifier = container.read(
        recurrenceManagementControllerProvider.notifier,
      );
      await notifier.resume('rule-1');

      final state = container.read(recurrenceManagementControllerProvider);
      expect(state, isA<AsyncData<void>>());
    });

    test('cancel — success transitions state to AsyncData', () async {
      when(() => mockRepo.cancel(any())).thenAnswer((_) async {});

      final notifier = container.read(
        recurrenceManagementControllerProvider.notifier,
      );
      await notifier.cancel('rule-1');

      final state = container.read(recurrenceManagementControllerProvider);
      expect(state, isA<AsyncData<void>>());
    });
  });
}
