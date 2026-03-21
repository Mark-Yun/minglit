import 'dart:async';
import 'dart:math' as math;

import 'package:app_user/src/features/explore/logic/eligibility_filter.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'explore_state_provider.g.dart';

enum ExploreSortType { recommended, closingSoon, nearestDate }

enum ExploreFilterType { eligibility, nearby, sort }

class ExploreFilters {
  const ExploreFilters({
    this.eligibilityEnabled = false,
    this.sortType = ExploreSortType.recommended,
    this.nearbyEnabled = false,
  });

  final bool eligibilityEnabled;
  final ExploreSortType sortType;
  final bool nearbyEnabled;

  bool get hasActiveFilters =>
      eligibilityEnabled ||
      nearbyEnabled ||
      sortType != ExploreSortType.recommended;

  int get activeFilterCount {
    var count = 0;
    if (eligibilityEnabled) count++;
    if (nearbyEnabled) count++;
    if (sortType != ExploreSortType.recommended) count++;
    return count;
  }

  ExploreFilters copyWith({
    bool? eligibilityEnabled,
    ExploreSortType? sortType,
    bool? nearbyEnabled,
  }) {
    return ExploreFilters(
      eligibilityEnabled: eligibilityEnabled ?? this.eligibilityEnabled,
      sortType: sortType ?? this.sortType,
      nearbyEnabled: nearbyEnabled ?? this.nearbyEnabled,
    );
  }
}

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  // Riverpod notifier method — cannot use setter syntax with code generation.
  // ignore: use_setters_to_change_properties
  void update(String query) => state = query;

  void clear() => state = '';
}

@riverpod
class ActiveFilters extends _$ActiveFilters {
  @override
  ExploreFilters build() => const ExploreFilters(
        eligibilityEnabled: true,
        nearbyEnabled: true,
      );

  // Riverpod notifier method — cannot use setter syntax with code generation.
  // ignore: use_setters_to_change_properties
  void update(ExploreFilters filters) => state = filters;

  void toggleEligibility() {
    state = state.copyWith(eligibilityEnabled: !state.eligibilityEnabled);
  }

  void setSortType(ExploreSortType type) {
    state = state.copyWith(sortType: type);
  }

  void toggleNearby() {
    state = state.copyWith(nearbyEnabled: !state.nearbyEnabled);
  }

  void clearAll() => state = const ExploreFilters();

  void removeFilter(ExploreFilterType type) {
    switch (type) {
      case ExploreFilterType.eligibility:
        state = state.copyWith(eligibilityEnabled: false);
      case ExploreFilterType.nearby:
        state = state.copyWith(nearbyEnabled: false);
      case ExploreFilterType.sort:
        state = state.copyWith(sortType: ExploreSortType.recommended);
    }
  }
}

@riverpod
Future<LocationResult?> userLocation(Ref ref) async {
  final service = LocationService();
  return service.getCurrentPosition();
}

@riverpod
Future<List<Event>> searchResults(Ref ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];

  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), link.close);
  ref.onDispose(timer.cancel);

  final repository = ref.watch(eventRepositoryProvider);
  final response = await repository.supabaseClient.rpc<List<dynamic>>(
    'search_events_pgroonga',
    params: {'query': query},
  );

  return response
      .map((item) => Event.fromJson(item as Map<String, dynamic>))
      .toList();
}

/// Fetches bulk eligibility data (user profile + verified status).
@riverpod
Future<BulkEligibilityData?> bulkEligibilityData(Ref ref) async {
  final user = ref.watch(currentUserProfileProvider).value;
  if (user == null) return null;

  final repository = ref.watch(eventRepositoryProvider);
  final response = await repository.getBulkEligibilityData(userId: user.id);
  return BulkEligibilityData.fromJson(response);
}

/// Applies active filters and nearby sort to a list of events (client-side).
///
/// Filter chain: eligibility → nearby sort
@riverpod
List<Event> filteredEvents(
  Ref ref, {
  required List<Event> events,
}) {
  final filters = ref.watch(activeFiltersProvider);
  if (!filters.hasActiveFilters) return events;

  var result = events;

  // 1. Eligibility filter — only apply when user is identity-verified.
  // Unverified users have no approved verifications, so the filter would
  // return an empty list. Skip it to show the full event list instead.
  if (filters.eligibilityEnabled) {
    final eligibility = ref.watch(bulkEligibilityDataProvider).value;
    if (eligibility != null && (eligibility.userProfile?.isVerified ?? false)) {
      result = EligibilityFilter.filter(
        events: result,
        eligibilityData: eligibility,
      );
    }
  }

  // 2. Nearby sort — sort by haversine distance ascending.
  // Events with lat==0.0 && lng==0.0 (unknown location) go to the end.
  if (filters.nearbyEnabled) {
    final userLoc = ref.watch(userLocationProvider).value;
    if (userLoc != null) {
      result = [...result]..sort((a, b) {
          final locA = a.location ?? a.party?.location;
          final locB = b.location ?? b.party?.location;
          final distA =
              (locA == null || (locA.latitude == 0.0 && locA.longitude == 0.0))
                  ? double.infinity
                  : _haversineDistance(
                      userLoc.latitude,
                      userLoc.longitude,
                      locA.latitude,
                      locA.longitude,
                    );
          final distB =
              (locB == null || (locB.latitude == 0.0 && locB.longitude == 0.0))
                  ? double.infinity
                  : _haversineDistance(
                      userLoc.latitude,
                      userLoc.longitude,
                      locB.latitude,
                      locB.longitude,
                    );
          return distA.compareTo(distB);
        });
    }
  }

  return result;
}

/// Pagination state for the recommendation feed.
class RecommendationFeedState {
  const RecommendationFeedState({
    required this.events,
    required this.serverOffset,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  /// Client-side filtered display events.
  final List<Event> events;

  /// Total events fetched from server (for next page offset).
  final int serverOffset;

  /// Whether more events might be available.
  final bool hasMore;

  /// Whether a loadMore() call is in progress.
  final bool isLoadingMore;

  RecommendationFeedState copyWith({
    List<Event>? events,
    int? serverOffset,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return RecommendationFeedState(
      events: events ?? this.events,
      serverOffset: serverOffset ?? this.serverOffset,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Manages pagination state for the recommendation event feed.
///
/// Tracks server-side offset separately from display count because
/// client-side filtering (eligibility + nearby sort) means the number
/// of displayed events may differ from the number fetched from server.
///
/// Filter changes (via [activeFiltersProvider]) automatically reset the
/// state to page 0.
@riverpod
class RecommendationFeedNotifier extends _$RecommendationFeedNotifier {
  static const int _limit = 10;

  /// Raw events accumulated from server (before client-side filtering).
  /// Reset on every [build] call (i.e., when filters change).
  List<Event> _rawEvents = [];

  /// Monotonically increasing generation counter.
  /// Incremented on each [build] call (filter change).
  /// Used to discard stale async results from previous builds.
  int _generation = 0;

  @override
  Future<RecommendationFeedState> build() async {
    // Reset raw accumulation and bump generation on every filter change
    _rawEvents = [];
    _generation++;
    final capturedGen = _generation;

    // Watch filters — triggers rebuild on change, resetting pagination
    final filters = ref.watch(activeFiltersProvider);

    final result = await _fetchPage(
      filters: filters,
      serverOffset: 0,
      generation: capturedGen,
    );

    // If a newer build started during our fetch, return empty state —
    // the newer build will overwrite this immediately.
    return result ??
        const RecommendationFeedState(
          events: [],
          serverOffset: 0,
          hasMore: false,
        );
  }

  /// Loads the next page of events.
  ///
  /// No-op if already loading or no more pages available.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null) return;
    if (current.isLoadingMore) return; // Concurrent guard
    if (!current.hasMore) return; // No more pages

    // Preserve existing data while indicating loading
    state = AsyncData(current.copyWith(isLoadingMore: true));

    final capturedGen = _generation;
    final filters = ref.read(activeFiltersProvider);
    try {
      final updated = await _fetchPage(
        filters: filters,
        serverOffset: current.serverOffset,
        generation: capturedGen,
      );
      if (!ref.mounted) return;
      // Discard if a filter change occurred during fetch
      if (updated == null) return;
      state = AsyncData(updated);
    } on Exception catch (_) {
      // On error: restore previous state, preserve existing events
      if (!ref.mounted) return;
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  /// Returns null if the result is stale (a newer generation started).
  Future<RecommendationFeedState?> _fetchPage({
    required ExploreFilters filters,
    required int serverOffset,
    required int generation,
  }) async {
    final feedType = _mapFeedType(filters.sortType);

    // Call repository directly to avoid Riverpod error-zone propagation
    // and to manage our own lifecycle (bypassing the 5-min per-page cache).
    final repository = ref.read(eventRepositoryProvider);
    final rawPage = await repository.getEventsByType(
      type: feedType,
      offset: serverOffset,
    );

    // Discard if a filter change (new generation) occurred during the fetch
    if (generation != _generation) return null;

    // Append new unique events to raw accumulation
    final existingIds = _rawEvents.map((e) => e.id).toSet();
    final newUnique =
        rawPage.where((e) => !existingIds.contains(e.id)).toList();
    _rawEvents = [..._rawEvents, ...newUnique];

    // Apply client-side filter + sort to full accumulated list
    final filtered = ref.read(filteredEventsProvider(events: _rawEvents));

    return RecommendationFeedState(
      events: filtered,
      serverOffset: serverOffset + rawPage.length,
      hasMore: rawPage.length >= _limit,
    );
  }

  EventFeedType _mapFeedType(ExploreSortType sortType) {
    return switch (sortType) {
      ExploreSortType.recommended => EventFeedType.newArrivals,
      ExploreSortType.closingSoon => EventFeedType.closingSoon,
      // Use nearest (date-sorted) rather than earlyBird, which applies an
      // additional ticket-name filter that would exclude non-early-bird events.
      ExploreSortType.nearestDate => EventFeedType.nearest,
    };
  }
}

/// Fetches and filters the unified recommendation event list.
///
/// Maps [ExploreSortType] to [EventFeedType]:
/// - recommended → newArrivals
/// - closingSoon → closingSoon
/// - nearestDate → nearest
@riverpod
Future<List<Event>> recommendationEvents(Ref ref) async {
  final filters = ref.watch(activeFiltersProvider);

  final feedType = switch (filters.sortType) {
    ExploreSortType.recommended => EventFeedType.newArrivals,
    ExploreSortType.closingSoon => EventFeedType.closingSoon,
    ExploreSortType.nearestDate => EventFeedType.nearest,
  };

  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), link.close);
  ref.onDispose(timer.cancel);

  final events = await ref.watch(
    fetchEventFeedProvider(type: feedType).future,
  );

  // Deduplicate by event ID (keep first occurrence)
  final seen = <String>{};
  final unique = events.where((e) => seen.add(e.id)).toList();

  // Apply eligibility filter + nearby sort
  return ref.watch(filteredEventsProvider(events: unique));
}

/// Haversine formula for distance between two GPS coordinates.
/// Returns distance in meters.
double _haversineDistance(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const earthRadius = 6371000.0; // meters
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) *
          math.cos(_toRadians(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadius * c;
}

double _toRadians(double degrees) => degrees * math.pi / 180;
