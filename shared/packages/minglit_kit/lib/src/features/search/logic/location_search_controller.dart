import 'dart:async';

import 'package:minglit_kit/src/data/models/party.dart';
import 'package:minglit_kit/src/data/repositories/kakao_location_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location_search_controller.g.dart';

/// Handles location search with debounce and async results.
@riverpod
class LocationSearchController extends _$LocationSearchController {
  Timer? _debounce;

  /// Initializes the search state with an empty list.
  @override
  FutureOr<List<Location>> build() {
    ref.onDispose(() {
      _debounce?.cancel();
    });
    // Initial state is empty list
    return [];
  }

  /// Debounces and searches locations for the given [query].
  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Debounce for 500ms
    _debounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(_performSearch(query));
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final repository = ref.read(kakaoLocationRepositoryProvider);
      final results = await repository.searchKeyword(query);
      state = AsyncValue.data(results);
    } on Exception catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
