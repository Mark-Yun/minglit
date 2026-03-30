import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/party.dart';
import 'package:minglit_kit/src/data/repositories/kakao_location_repository.dart';
import 'package:minglit_kit/src/features/search/logic/location_search_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_utils.dart';

class MockKakaoLocationRepository extends Mock
    implements KakaoLocationRepository {}

/// Test subclass that bypasses the 500ms debounce timer, allowing
/// direct testing of search logic without real-time delays.
class _DirectSearchController extends LocationSearchController {
  /// Exposed future for the last search so tests can await it.
  Future<void>? lastSearch;

  @override
  void onSearchChanged(String query) {
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    lastSearch = _doSearch(query);
  }

  Future<void> _doSearch(String query) async {
    try {
      final results = await ref
          .read(kakaoLocationRepositoryProvider)
          .searchKeyword(query);
      state = AsyncValue.data(results);
    } on Exception catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

void main() {
  late MockKakaoLocationRepository mockRepo;

  final now = DateTime(2026, 3, 20);

  setUp(() {
    mockRepo = MockKakaoLocationRepository();
  });

  ProviderContainer createTestContainer() {
    return createContainer(
      overrides: [
        kakaoLocationRepositoryProvider.overrideWithValue(mockRepo),
        locationSearchControllerProvider.overrideWith(
          _DirectSearchController.new,
        ),
      ],
    );
  }

  group('LocationSearchController', () {
    test('initial state is empty list', () async {
      final container = createTestContainer();

      final result = await container.read(
        locationSearchControllerProvider.future,
      );

      expect(result, isEmpty);
    });

    test('search returns results from repository', () async {
      final locations = <Location>[
        Location(
          id: 'loc_1',
          partnerId: 'p_1',
          name: '강남역',
          address: '서울 강남구 강남대로 396',
          createdAt: now,
          updatedAt: now,
        ),
      ];
      when(
        () => mockRepo.searchKeyword('강남'),
      ).thenAnswer((_) async => locations);

      final container = createTestContainer();
      await container.read(locationSearchControllerProvider.future);

      final notifier = container.read(
        locationSearchControllerProvider.notifier,
      )..onSearchChanged('강남');
      await (notifier as _DirectSearchController).lastSearch;

      final state = container.read(locationSearchControllerProvider);
      expect(state.value, equals(locations));
      verify(() => mockRepo.searchKeyword('강남')).called(1);
    });

    test('empty query clears results without API call', () async {
      final container = createTestContainer();
      await container.read(locationSearchControllerProvider.future);

      container
          .read(locationSearchControllerProvider.notifier)
          .onSearchChanged('');

      final state = container.read(locationSearchControllerProvider);
      expect(state.value, isEmpty);
      verifyNever(() => mockRepo.searchKeyword(any()));
    });

    test('error from repository sets error state', () async {
      when(
        () => mockRepo.searchKeyword('에러'),
      ).thenAnswer(
        (_) => Future<List<Location>>.error(
          Exception('Network error'),
        ),
      );

      final container = createTestContainer();
      await container.read(locationSearchControllerProvider.future);

      final notifier = container.read(
        locationSearchControllerProvider.notifier,
      )..onSearchChanged('에러');
      await (notifier as _DirectSearchController).lastSearch;

      final state = container.read(locationSearchControllerProvider);
      expect(state, isA<AsyncError<List<Location>>>());
    });
  });
}
