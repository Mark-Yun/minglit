import 'dart:async';
import 'dart:math' as math;

import 'package:app_user/src/features/explore/logic/eligibility_filter.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:minglit_kit/src/data/repositories/event_repository.dart';
import 'package:minglit_kit/src/services/location_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'explore_state_provider.g.dart';

enum ExploreFilterType { eligibility, location, price, date }

class ExploreFilters {
  const ExploreFilters({
    this.eligibilityEnabled = false,
    this.locationRadiusMeters,
    this.priceMin,
    this.priceMax,
    this.dateStart,
    this.dateEnd,
  });

  final bool eligibilityEnabled;
  final int? locationRadiusMeters;
  final int? priceMin;
  final int? priceMax;
  final DateTime? dateStart;
  final DateTime? dateEnd;

  bool get hasActiveFilters =>
      eligibilityEnabled ||
      locationRadiusMeters != null ||
      priceMin != null ||
      priceMax != null ||
      dateStart != null ||
      dateEnd != null;

  int get activeFilterCount {
    var count = 0;
    if (eligibilityEnabled) count++;
    if (locationRadiusMeters != null) count++;
    if (priceMin != null || priceMax != null) count++;
    if (dateStart != null || dateEnd != null) count++;
    return count;
  }

  ExploreFilters copyWith({
    bool? eligibilityEnabled,
    int? Function()? locationRadiusMeters,
    int? Function()? priceMin,
    int? Function()? priceMax,
    DateTime? Function()? dateStart,
    DateTime? Function()? dateEnd,
  }) {
    return ExploreFilters(
      eligibilityEnabled: eligibilityEnabled ?? this.eligibilityEnabled,
      locationRadiusMeters: locationRadiusMeters != null
          ? locationRadiusMeters()
          : this.locationRadiusMeters,
      priceMin: priceMin != null ? priceMin() : this.priceMin,
      priceMax: priceMax != null ? priceMax() : this.priceMax,
      dateStart: dateStart != null ? dateStart() : this.dateStart,
      dateEnd: dateEnd != null ? dateEnd() : this.dateEnd,
    );
  }
}

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void update(String query) => state = query;

  void clear() => state = '';
}

@riverpod
class ActiveFilters extends _$ActiveFilters {
  @override
  ExploreFilters build() => const ExploreFilters();

  void update(ExploreFilters filters) => state = filters;

  void toggleEligibility() {
    state = state.copyWith(eligibilityEnabled: !state.eligibilityEnabled);
  }

  void setLocationRadius(int? meters) {
    state = state.copyWith(locationRadiusMeters: () => meters);
  }

  void setPriceRange({int? min, int? max}) {
    state = state.copyWith(priceMin: () => min, priceMax: () => max);
  }

  void setDateRange({DateTime? start, DateTime? end}) {
    state = state.copyWith(dateStart: () => start, dateEnd: () => end);
  }

  void clearAll() => state = const ExploreFilters();

  void removeFilter(ExploreFilterType type) {
    switch (type) {
      case ExploreFilterType.eligibility:
        state = state.copyWith(eligibilityEnabled: false);
      case ExploreFilterType.location:
        state = state.copyWith(locationRadiusMeters: () => null);
      case ExploreFilterType.price:
        state = state.copyWith(priceMin: () => null, priceMax: () => null);
      case ExploreFilterType.date:
        state = state.copyWith(dateStart: () => null, dateEnd: () => null);
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

@riverpod
Future<List<Event>> aiRecommendations(Ref ref) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), link.close);
  ref.onDispose(timer.cancel);

  final user = ref.watch(currentUserProfileProvider).value;
  if (user == null) return [];

  final repository = ref.watch(eventRepositoryProvider);
  final results = await repository.getPersonalizedRecommendations(
    userId: user.id,
    limit: 10,
  );

  return results.map((item) {
    return Event.fromJson({
      'id': item['event_id'],
      'title': item['event_title'],
      'description': item['event_description'],
      'image_urls': item['event_image_urls'],
      'start_time': item['event_start_time'],
      'end_time': item['event_end_time'],
      'status': item['event_status'],
      'max_participants': item['event_max_participants'],
      'current_participants': item['event_current_participants'],
      'party': {
        'id': item['party_id'],
        'title': item['party_title'],
        'image_urls': item['party_image_urls'],
        'partner_id': '',
        'location': item['location_id'] != null
            ? {
                'id': item['location_id'],
                'name': item['location_name'],
                'address': item['location_address'],
                'partner_id': '',
              }
            : null,
      },
      'party_id': item['party_id'],
    });
  }).toList();
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

/// Applies all active filters to a list of events (client-side).
///
/// Filter chain: eligibility → location → price → date
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

  // 2. Location filter
  if (filters.locationRadiusMeters != null) {
    final userLoc = ref.watch(userLocationProvider).value;
    if (userLoc != null) {
      final radiusMeters = filters.locationRadiusMeters!;
      result = result.where((event) {
        final loc = event.location ?? event.party?.location;
        if (loc == null) return false;
        final distance = _haversineDistance(
          userLoc.latitude,
          userLoc.longitude,
          loc.latitude,
          loc.longitude,
        );
        return distance <= radiusMeters;
      }).toList();
    }
  }

  // 3. Price filter
  if (filters.priceMin != null || filters.priceMax != null) {
    result = result.where((event) {
      final tickets = event.tickets;
      if (tickets == null || tickets.isEmpty) {
        // Events without tickets are treated as free (price = 0)
        final price = 0;
        return _priceInRange(price, filters.priceMin, filters.priceMax);
      }
      // Check if any ticket falls within the price range
      return tickets.any(
        (t) => _priceInRange(t.price, filters.priceMin, filters.priceMax),
      );
    }).toList();
  }

  // 4. Date filter
  if (filters.dateStart != null || filters.dateEnd != null) {
    result = result.where((event) {
      if (filters.dateStart != null &&
          event.startTime.isBefore(filters.dateStart!)) {
        return false;
      }
      if (filters.dateEnd != null) {
        final endOfDay = DateTime(
          filters.dateEnd!.year,
          filters.dateEnd!.month,
          filters.dateEnd!.day,
          23,
          59,
          59,
        );
        if (event.startTime.isAfter(endOfDay)) return false;
      }
      return true;
    }).toList();
  }

  return result;
}

bool _priceInRange(int price, int? min, int? max) {
  if (min != null && price < min) return false;
  if (max != null && price > max) return false;
  return true;
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
