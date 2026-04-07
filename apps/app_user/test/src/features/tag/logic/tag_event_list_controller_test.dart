import 'package:app_user/src/features/tag/logic/tag_event_list_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';
import '../../../../utils/test_utils.dart';

void main() {
  late MockTagRepository mockTagRepo;

  final now = DateTime.now();

  Event makeEvent(String id) => Event(
    id: id,
    partyId: 'party_1',
    startTime: now.add(const Duration(days: 1)),
    endTime: now.add(const Duration(days: 1, hours: 2)),
    createdAt: now,
    updatedAt: now,
    title: 'Event $id',
  );

  setUp(() {
    mockTagRepo = MockTagRepository();
    // Default: returns empty
    when(
      () => mockTagRepo.getPartiesByTag(
        any(),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => []);
  });

  group('TagEventListController', () {
    test(
      'initial build fetches first page and sets hasMore=true when full page',
      () async {
        final events = List.generate(10, (i) => makeEvent('e$i'));
        when(
          () => mockTagRepo.getPartiesByTag(
            'tag_1',
          ),
        ).thenAnswer((_) async => events);

        final container = createContainer(
          overrides: [
            tagRepositoryProvider.overrideWith((ref) => mockTagRepo),
          ],
        );

        final result = await container.read(
          tagEventListControllerProvider('tag_1').future,
        );

        expect(result.events, hasLength(10));
        expect(result.hasMore, isTrue);
        expect(result.isLoadingMore, isFalse);
      },
    );

    test(
      'initial build sets hasMore=false when fewer than page-size returned',
      () async {
        final events = List.generate(3, (i) => makeEvent('e$i'));
        when(
          () => mockTagRepo.getPartiesByTag(
            'tag_1',
          ),
        ).thenAnswer((_) async => events);

        final container = createContainer(
          overrides: [
            tagRepositoryProvider.overrideWith((ref) => mockTagRepo),
          ],
        );

        final result = await container.read(
          tagEventListControllerProvider('tag_1').future,
        );

        expect(result.events, hasLength(3));
        expect(result.hasMore, isFalse);
      },
    );

    test('loadMore appends next page to existing events', () async {
      final firstPage = List.generate(10, (i) => makeEvent('first_$i'));
      final secondPage = List.generate(5, (i) => makeEvent('second_$i'));

      when(
        () => mockTagRepo.getPartiesByTag(
          'tag_1',
        ),
      ).thenAnswer((_) async => firstPage);
      when(
        () => mockTagRepo.getPartiesByTag(
          'tag_1',
          offset: 10,
        ),
      ).thenAnswer((_) async => secondPage);

      final container = createContainer(
        overrides: [
          tagRepositoryProvider.overrideWith((ref) => mockTagRepo),
        ],
      );

      // Wait for initial build
      await container.read(tagEventListControllerProvider('tag_1').future);

      // Load more
      await container
          .read(tagEventListControllerProvider('tag_1').notifier)
          .loadMore();

      final state = container
          .read(tagEventListControllerProvider('tag_1'))
          .value!;
      expect(state.events, hasLength(15));
      expect(state.hasMore, isFalse);
      expect(state.isLoadingMore, isFalse);
    });

    test('loadMore is no-op when hasMore is false', () async {
      final events = List.generate(3, (i) => makeEvent('e$i'));
      when(
        () => mockTagRepo.getPartiesByTag(
          'tag_1',
        ),
      ).thenAnswer((_) async => events);

      final container = createContainer(
        overrides: [
          tagRepositoryProvider.overrideWith((ref) => mockTagRepo),
        ],
      );

      await container.read(tagEventListControllerProvider('tag_1').future);
      await container
          .read(tagEventListControllerProvider('tag_1').notifier)
          .loadMore();

      // getPartiesByTag should only have been called once (initial build)
      verify(
        () => mockTagRepo.getPartiesByTag(
          'tag_1',
        ),
      ).called(1);
    });

    test('concurrent loadMore calls do not double-fetch', () async {
      final firstPage = List.generate(10, (i) => makeEvent('e$i'));
      final secondPage = List.generate(5, (i) => makeEvent('second_$i'));
      when(
        () => mockTagRepo.getPartiesByTag(
          'tag_1',
        ),
      ).thenAnswer((_) async => firstPage);
      when(
        () => mockTagRepo.getPartiesByTag(
          'tag_1',
          offset: 10,
        ),
      ).thenAnswer((_) async => secondPage);

      final container = createContainer(
        overrides: [
          tagRepositoryProvider.overrideWith((ref) => mockTagRepo),
        ],
      );

      await container.read(tagEventListControllerProvider('tag_1').future);

      final notifier = container.read(
        tagEventListControllerProvider('tag_1').notifier,
      );

      // Fire two concurrent loadMore calls; guard should prevent double-fetch
      await Future.wait([notifier.loadMore(), notifier.loadMore()]);

      // offset=10 should be called exactly once due to isLoadingMore guard
      verify(
        () => mockTagRepo.getPartiesByTag('tag_1', offset: 10),
      ).called(1);
    });

    test('initial build emits AsyncError on network failure', () async {
      when(
        () => mockTagRepo.getPartiesByTag(
          'tag_1',
        ),
      ).thenAnswer((_) async => throw Exception('Network error'));

      final container = createContainer(
        overrides: [
          tagRepositoryProvider.overrideWith((ref) => mockTagRepo),
        ],
      );

      // Keep the provider alive while awaiting the future.
      // Without listen(), container.read() disposes the provider mid-build.
      final sub = container.listen(
        tagEventListControllerProvider('tag_1'),
        (_, _) {},
      );

      // Awaiting the future forces the provider build to complete (and throw).
      await expectLater(
        container.read(tagEventListControllerProvider('tag_1').future),
        throwsA(isA<Exception>()),
      );

      // Now the provider has settled into AsyncError.
      final state = container.read(tagEventListControllerProvider('tag_1'));
      expect(state, isA<AsyncError<TagEventListState>>());

      sub.close();
    });

    // Fix regression: loadMore error restores previous state without spinner
    test('loadMore restores isLoadingMore=false on error', () async {
      final firstPage = List.generate(10, (i) => makeEvent('e$i'));
      when(
        () => mockTagRepo.getPartiesByTag(
          'tag_1',
        ),
      ).thenAnswer((_) async => firstPage);
      when(
        () => mockTagRepo.getPartiesByTag(
          'tag_1',
          offset: 10,
        ),
      ).thenThrow(Exception('Network error'));

      final container = createContainer(
        overrides: [
          tagRepositoryProvider.overrideWith((ref) => mockTagRepo),
        ],
      );

      await container.read(tagEventListControllerProvider('tag_1').future);

      // loadMore() no longer re-throws — it catches internally so that
      // unawaited(loadMore()) in _onScroll doesn't produce unhandled errors.
      await container
          .read(tagEventListControllerProvider('tag_1').notifier)
          .loadMore();

      final state = container
          .read(tagEventListControllerProvider('tag_1'))
          .value!;
      expect(state.isLoadingMore, isFalse);
      // Original events should still be present
      expect(state.events, hasLength(10));
    });
  });
}
