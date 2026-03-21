import 'package:app_partner/src/features/party/matching/matching_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

Future<void> pump() async {
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

void main() {
  late MockMatchingRepository mockRepo;

  setUp(() {
    mockRepo = MockMatchingRepository();
  });

  ProviderContainer makeContainer() {
    return createContainer(
      overrides: [
        matchingRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  }

  group('MatchingController', () {
    test('initial state is AsyncData(null)', () {
      final container = makeContainer();
      final sub = container.listen(
        matchingControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      final state = container.read(matchingControllerProvider);
      expect(state, isA<AsyncData<void>>());
    });

    test('updateRules transitions to loading then success', () async {
      when(
        () => mockRepo.updateMatchRules(
          eventId: any(named: 'eventId'),
          rules: any(named: 'rules'),
        ),
      ).thenAnswer((_) async {});

      final container = makeContainer();
      final sub = container.listen(
        matchingControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      await container
          .read(matchingControllerProvider.notifier)
          .updateRules(eventId: 'event-1', rules: []);

      final state = container.read(matchingControllerProvider);
      expect(state, isA<AsyncData<void>>());
      verify(
        () => mockRepo.updateMatchRules(eventId: 'event-1', rules: []),
      ).called(1);
    });

    test('updateRules sets AsyncError on failure', () async {
      when(
        () => mockRepo.updateMatchRules(
          eventId: any(named: 'eventId'),
          rules: any(named: 'rules'),
        ),
      ).thenThrow(Exception('update failed'));

      final container = makeContainer();
      final sub = container.listen(
        matchingControllerProvider,
        (_, _) {},
      );
      addTearDown(sub.close);

      await container
          .read(matchingControllerProvider.notifier)
          .updateRules(eventId: 'event-1', rules: []);

      final state = container.read(matchingControllerProvider);
      expect(state, isA<AsyncError<void>>());
    });
  });

  group('eventMatchRulesProvider', () {
    test('returns match rules from repository', () async {
      final rules = [
        MatchRule(
          id: 'rule-1',
          eventId: 'event-1',
          sourceGroupId: 'group-a',
          targetGroupId: 'group-b',
          createdAt: DateTime(2024),
        ),
      ];
      when(
        () => mockRepo.getMatchRules('event-1'),
      ).thenAnswer((_) async => rules);

      final container = makeContainer();
      final result =
          await container.read(eventMatchRulesProvider('event-1').future);
      expect(result.length, 1);
      expect(result.first.id, 'rule-1');
    });

    test('returns empty list when no rules exist', () async {
      when(
        () => mockRepo.getMatchRules('event-empty'),
      ).thenAnswer((_) async => []);

      final container = makeContainer();
      final result =
          await container.read(eventMatchRulesProvider('event-empty').future);
      expect(result, isEmpty);
    });
  });
}
