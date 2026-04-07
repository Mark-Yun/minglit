import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tag_event_list_controller.g.dart';

/// State for the paginated tag event list.
class TagEventListState {
  const TagEventListState({
    this.events = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final List<Event> events;
  final bool hasMore;
  final bool isLoadingMore;

  TagEventListState copyWith({
    List<Event>? events,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return TagEventListState(
      events: events ?? this.events,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Manages the paginated list of events for a given tag.
@riverpod
class TagEventListController extends _$TagEventListController {
  static const _pageSize = 10;

  @override
  Future<TagEventListState> build(String tagId) async {
    final events = await _fetchPage(offset: 0);
    return TagEventListState(
      events: events,
      hasMore: events.length >= _pageSize,
    );
  }

  /// Loads the next page of events.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final next = await _fetchPage(offset: current.events.length);
      state = AsyncData(
        current.copyWith(
          events: [...current.events, ...next],
          hasMore: next.length >= _pageSize,
          isLoadingMore: false,
        ),
      );
    } catch (e, st) {
      // Restore previous state without loading indicator on error
      state = AsyncData(current.copyWith(isLoadingMore: false));
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<List<Event>> _fetchPage({required int offset}) {
    final repository = ref.read(tagRepositoryProvider);
    return repository.getPartiesByTag(
      tagId,
      limit: _pageSize,
      offset: offset,
    );
  }
}
