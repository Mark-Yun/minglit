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

  // 1. Eligibility filter
  if (filters.eligibilityEnabled) {
    final eligibility = ref.watch(bulkEligibilityDataProvider).value;
    if (eligibility != null) {
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
      result = [...result]
        ..sort((a, b) {
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

/// Fetches and filters the unified recommendation event list.
///
/// Maps [ExploreSortType] to [EventFeedType]:
/// - recommended → newArrivals
/// - closingSoon → closingSoon
/// - nearestDate → earlyBird
@riverpod
Future<List<Event>> recommendationEvents(Ref ref) async {
  final filters = ref.watch(activeFiltersProvider);

  final feedType = switch (filters.sortType) {
    ExploreSortType.recommended => EventFeedType.newArrivals,
    ExploreSortType.closingSoon => EventFeedType.closingSoon,
    ExploreSortType.nearestDate => EventFeedType.earlyBird,
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
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) *
          math.cos(_toRadians(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadius * c;
}

double _toRadians(double degrees) => degrees * math.pi / 180;
