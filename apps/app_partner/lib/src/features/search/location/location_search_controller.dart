import 'dart:async';

import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'location_search_controller.g.dart';

@riverpod
class LocationSearchController extends _$LocationSearchController {
  Timer? _debounce;

  @override
  FutureOr<List<Location>> build() {
    // Initial state is empty list
    return [];
  }

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
