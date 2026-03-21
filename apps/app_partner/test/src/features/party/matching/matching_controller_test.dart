import 'package:app_partner/src/features/party/matching/matching_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

Future<void> pump() async {
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

void main() {
  late MockMatchingRepository mockMatchingRepo;

  setUp(() {
    mockMatchingRepo = MockMatchingRepository();
  });

  group('MatchingController', () {
    group('updateRules', () {
      test('updates rules successfully', () async {
        final rules = [
          {'source_group_id': 'g1', 'target_group_id': 'g2'},
        ];

        when(
          () => mockMatchingRepo.updateMatchRules(
            eventId: 'event_1',
            rules: rules,
          ),
        ).thenAnswer((_) async {});

        final container = createContainer(
          overrides: [
            matchingRepositoryProvider.overrideWithValue(mockMatchingRepo),
          ],
        );

        // Listen to controller to initialize
        final sub = container.listen(
          matchingControllerProvider,
          (_, __) {},
        );
        addTearDown(sub.close);
        await pump();

        final notifier = container.read(
          matchingControllerProvider.notifier,
        );

        await notifier.updateRules(eventId: 'event_1', rules: rules);

        final state = container.read(matchingControllerProvider);
        expect(state, isA<AsyncData<void>>());
        verify(
          () => mockMatchingRepo.updateMatchRules(
            eventId: 'event_1',
            rules: rules,
          ),
        ).called(1);
      });

      test('sets error state on failure', () async {
        when(
          () => mockMatchingRepo.updateMatchRules(
            eventId: any(named: 'eventId'),
            rules: any(named: 'rules'),
          ),
        ).thenThrow(Exception('Update failed'));

        final container = createContainer(
          overrides: [
            matchingRepositoryProvider.overrideWithValue(mockMatchingRepo),
          ],
        );

        final sub = container.listen(
          matchingControllerProvider,
          (_, __) {},
        );
        addTearDown(sub.close);
        await pump();

        final notifier = container.read(
          matchingControllerProvider.notifier,
        );

        await notifier.updateRules(eventId: 'event_1', rules: []);

        final state = container.read(matchingControllerProvider);
        expect(state, isA<AsyncError<void>>());
      });
    });
  });

  group('eventMatchRules', () {
    test('returns match rules for event', () async {
      final rules = [
        MatchRule(
          id: 'rule-1',
          eventId: 'event_1',
          sourceGroupId: 'g1',
          targetGroupId: 'g2',
          createdAt: DateTime.now(),
        ),
        MatchRule(
          id: 'rule-2',
          eventId: 'event_1',
          sourceGroupId: 'g2',
          targetGroupId: 'g1',
          createdAt: DateTime.now(),
        ),
      ];

      when(
        () => mockMatchingRepo.getMatchRules('event_1'),
      ).thenAnswer((_) async => rules);

      final container = createContainer(
        overrides: [
          matchingRepositoryProvider.overrideWithValue(mockMatchingRepo),
        ],
      );

      final result = await container.read(
        eventMatchRulesProvider('event_1').future,
      );

      expect(result, hasLength(2));
      expect(result.first.sourceGroupId, 'g1');
      expect(result.last.targetGroupId, 'g1');
      verify(() => mockMatchingRepo.getMatchRules('event_1')).called(1);
    });

    test('returns empty list when no rules exist', () async {
      when(
        () => mockMatchingRepo.getMatchRules('event_empty'),
      ).thenAnswer((_) async => []);

      final container = createContainer(
        overrides: [
          matchingRepositoryProvider.overrideWithValue(mockMatchingRepo),
        ],
      );

      final result = await container.read(
        eventMatchRulesProvider('event_empty').future,
      );

      expect(result, isEmpty);
    });

    test('propagates error when repository throws', () async {
      when(
        () => mockMatchingRepo.getMatchRules('event_err'),
      ).thenAnswer((_) async => throw Exception('DB error'));

      final container = createContainer(
        overrides: [
          matchingRepositoryProvider.overrideWithValue(mockMatchingRepo),
        ],
      );

      final sub = container.listen(
        eventMatchRulesProvider('event_err'),
        (_, __) {},
      );
      addTearDown(sub.close);

      await pump();

      final state = container.read(eventMatchRulesProvider('event_err'));
      expect(state.hasError, isTrue);
    });
  });
}
