import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../../../../utils/test_utils.dart';

void main() {
  final now = DateTime.now();

  Event makeEvent({
    String id = 'e1',
    List<Ticket>? tickets,
    DateTime? startTime,
    Location? location,
    Party? party,
    int maxParticipants = 20,
    int currentParticipants = 0,
  }) {
    return Event(
      id: id,
      partyId: 'p1',
      startTime: startTime ?? now.add(const Duration(days: 1)),
      endTime: (startTime ?? now.add(const Duration(days: 1))).add(
        const Duration(hours: 2),
      ),
      createdAt: now,
      updatedAt: now,
      tickets: tickets,
      location: location,
      party: party,
      maxParticipants: maxParticipants,
      currentParticipants: currentParticipants,
    );
  }

  Location makeLocation({
    double lat = 37.5665,
    double lng = 126.978,
  }) {
    return Location(
      id: 'loc1',
      partnerId: 'partner1',
      name: 'Test Venue',
      address: 'Seoul',
      createdAt: now,
      updatedAt: now,
      latitude: lat,
      longitude: lng,
    );
  }

  group('ExploreFilters', () {
    test('initial state has no active filters', () {
      const filters = ExploreFilters();
      expect(filters.hasActiveFilters, false);
      expect(filters.activeFilterCount, 0);
    });

    test('tracks eligibility filter', () {
      const filters = ExploreFilters(eligibilityEnabled: true);
      expect(filters.hasActiveFilters, true);
      expect(filters.activeFilterCount, 1);
    });

    test('tracks nearby filter', () {
      const filters = ExploreFilters(nearbyEnabled: true);
      expect(filters.hasActiveFilters, true);
      expect(filters.activeFilterCount, 1);
    });

    test('tracks sort filter when not recommended', () {
      const filters = ExploreFilters(sortType: ExploreSortType.closingSoon);
      expect(filters.hasActiveFilters, true);
      expect(filters.activeFilterCount, 1);
    });

    test('recommended sort type is not counted as active filter', () {
      const filters = ExploreFilters();
      expect(filters.hasActiveFilters, false);
      expect(filters.activeFilterCount, 0);
    });

    test('counts multiple active filters', () {
      const filters = ExploreFilters(
        eligibilityEnabled: true,
        nearbyEnabled: true,
        sortType: ExploreSortType.closingSoon,
      );
      expect(filters.activeFilterCount, 3);
    });

    test('copyWith updates fields correctly', () {
      const filters = ExploreFilters(
        eligibilityEnabled: true,
        sortType: ExploreSortType.closingSoon,
        nearbyEnabled: true,
      );
      final updated = filters.copyWith(
        eligibilityEnabled: false,
        sortType: ExploreSortType.recommended,
        nearbyEnabled: false,
      );
      expect(updated.eligibilityEnabled, false);
      expect(updated.sortType, ExploreSortType.recommended);
      expect(updated.nearbyEnabled, false);
      expect(updated.hasActiveFilters, false);
    });
  });

  group('SearchQuery provider', () {
    test('initial state is empty string', () {
      final container = createContainer();
      expect(container.read(searchQueryProvider), '');
    });

    test('update changes query', () {
      final container = createContainer();
      container.read(searchQueryProvider.notifier).update('직장인');
      expect(container.read(searchQueryProvider), '직장인');
    });

    test('clear resets to empty', () {
      final container = createContainer();
      container.read(searchQueryProvider.notifier).update('test');
      container.read(searchQueryProvider.notifier).clear();
      expect(container.read(searchQueryProvider), '');
    });
  });

  group('ActiveFilters provider', () {
    test('initial state has eligibility and nearby enabled', () {
      final container = createContainer();
      final filters = container.read(activeFiltersProvider);
      expect(filters.hasActiveFilters, true);
      expect(filters.eligibilityEnabled, true);
      expect(filters.nearbyEnabled, true);
      expect(filters.activeFilterCount, 2);
    });

    test('toggleEligibility flips the flag', () {
      final container = createContainer();
      // Initial state: eligibilityEnabled = true
      expect(container.read(activeFiltersProvider).eligibilityEnabled, true);
      container.read(activeFiltersProvider.notifier).toggleEligibility();
      expect(
        container.read(activeFiltersProvider).eligibilityEnabled,
        false,
      );
      container.read(activeFiltersProvider.notifier).toggleEligibility();
      expect(
        container.read(activeFiltersProvider).eligibilityEnabled,
        true,
      );
    });

    test('setSortType updates sort type', () {
      final container = createContainer();
      container
          .read(activeFiltersProvider.notifier)
          .setSortType(ExploreSortType.closingSoon);
      expect(
        container.read(activeFiltersProvider).sortType,
        ExploreSortType.closingSoon,
      );
    });

    test('toggleNearby flips the flag', () {
      final container = createContainer();
      // Initial state: nearbyEnabled = true
      expect(container.read(activeFiltersProvider).nearbyEnabled, true);
      container.read(activeFiltersProvider.notifier).toggleNearby();
      expect(container.read(activeFiltersProvider).nearbyEnabled, false);
      container.read(activeFiltersProvider.notifier).toggleNearby();
      expect(container.read(activeFiltersProvider).nearbyEnabled, true);
    });

    test('clearAll resets all filters', () {
      final container = createContainer();
      container.read(activeFiltersProvider.notifier).toggleEligibility();
      container
          .read(activeFiltersProvider.notifier)
          .setSortType(ExploreSortType.closingSoon);
      container.read(activeFiltersProvider.notifier).toggleNearby();
      container.read(activeFiltersProvider.notifier).clearAll();

      final filters = container.read(activeFiltersProvider);
      expect(filters.hasActiveFilters, false);
      expect(filters.sortType, ExploreSortType.recommended);
    });

    test('removeFilter removes eligibility filter', () {
      final container = createContainer();
      container.read(activeFiltersProvider.notifier).toggleEligibility();
      container
          .read(activeFiltersProvider.notifier)
          .setSortType(ExploreSortType.closingSoon);

      container
          .read(activeFiltersProvider.notifier)
          .removeFilter(ExploreFilterType.eligibility);

      final filters = container.read(activeFiltersProvider);
      expect(filters.eligibilityEnabled, false);
      expect(filters.sortType, ExploreSortType.closingSoon);
    });

    test('removeFilter removes nearby filter', () {
      final container = createContainer();
      // Initial state: nearbyEnabled = true, eligibilityEnabled = true

      container
          .read(activeFiltersProvider.notifier)
          .removeFilter(ExploreFilterType.nearby);

      final filters = container.read(activeFiltersProvider);
      expect(filters.nearbyEnabled, false);
      expect(filters.eligibilityEnabled, true);
    });

    test('removeFilter resets sort to recommended', () {
      final container = createContainer();
      container
          .read(activeFiltersProvider.notifier)
          .setSortType(ExploreSortType.nearestDate);

      container
          .read(activeFiltersProvider.notifier)
          .removeFilter(ExploreFilterType.sort);

      final filters = container.read(activeFiltersProvider);
      expect(filters.sortType, ExploreSortType.recommended);
    });
  });

  group('filteredEventsProvider', () {
    test('returns all events when no filters active', () {
      final events = [
        makeEvent(),
        makeEvent(id: 'e2'),
      ];

      final container = createContainer();
      final result = container.read(
        filteredEventsProvider(events: events),
      );
      expect(result, hasLength(2));
    });

    test('filters by eligibility when enabled', () {
      // Without eligibility data, filter returns empty list
      final events = [makeEvent(), makeEvent(id: 'e2')];

      final container = createContainer();
      container.read(activeFiltersProvider.notifier).toggleEligibility();

      final result = container.read(
        filteredEventsProvider(events: events),
      );

      // bulkEligibilityData is null (no user), so eligibility filter returns
      // the original list unchanged
      // (guard: if eligibility == null, skip filter)
      expect(result, hasLength(2));
    });

    test('sorts by nearby distance when nearbyEnabled', () async {
      // Seoul City Hall: 37.5665, 126.978
      // Gangnam Station: 37.498, 127.028 (~8km away)
      // Incheon Airport: 37.469, 126.451 (~47km away)
      final seoulLoc = makeLocation();
      final gangnamLoc = makeLocation(lat: 37.498, lng: 127.028);
      final incheonLoc = makeLocation(lat: 37.469, lng: 126.451);

      final events = [
        makeEvent(id: 'incheon', location: incheonLoc),
        makeEvent(id: 'gangnam', location: gangnamLoc),
        makeEvent(id: 'seoul', location: seoulLoc),
      ];

      final container = createContainer(
        overrides: [
          // Mock user location at Seoul City Hall
          userLocationProvider.overrideWith(
            (ref) async => const LocationResult(
              latitude: 37.5665,
              longitude: 126.978,
            ),
          ),
        ],
      );

      // nearbyEnabled is true by default — no need to toggle

      // Wait for the async userLocation provider to resolve
      await container.read(userLocationProvider.future);

      final result = container.read(
        filteredEventsProvider(events: events),
      );

      // Should be sorted: seoul (0km) → gangnam (~8km) → incheon (~47km)
      expect(result[0].id, 'seoul');
      expect(result[1].id, 'gangnam');
      expect(result[2].id, 'incheon');
    });

    test('closingSoon sorts by remaining slots ASC', () {
      final events = [
        makeEvent(
          id: 'e1',
          maxParticipants: 20,
          currentParticipants: 5,
        ), // 15 remaining
        makeEvent(
          id: 'e2',
          maxParticipants: 10,
          currentParticipants: 8,
        ), // 2 remaining
        makeEvent(
          id: 'e3',
          maxParticipants: 30,
          currentParticipants: 25,
        ), // 5 remaining
      ];

      final container = createContainer();
      // Disable nearby + eligibility, enable closingSoon sort only
      container.read(activeFiltersProvider.notifier).toggleEligibility();
      container.read(activeFiltersProvider.notifier).toggleNearby();
      container
          .read(activeFiltersProvider.notifier)
          .setSortType(ExploreSortType.closingSoon);

      final result = container.read(
        filteredEventsProvider(events: events),
      );

      // Sorted: e2 (2) → e3 (5) → e1 (15)
      expect(result[0].id, 'e2');
      expect(result[1].id, 'e3');
      expect(result[2].id, 'e1');
    });

    test(
      'closingSoon + eligibility excludes fully booked events',
      () {
        final events = [
          makeEvent(
            id: 'available',
            maxParticipants: 10,
            currentParticipants: 8,
          ), // 2 remaining
          makeEvent(
            id: 'full',
            maxParticipants: 10,
            currentParticipants: 10,
          ), // 0 remaining
        ];

        final container = createContainer();
        // eligibility is enabled by default; disable nearby
        container.read(activeFiltersProvider.notifier).toggleNearby();
        container
            .read(activeFiltersProvider.notifier)
            .setSortType(ExploreSortType.closingSoon);

        final result = container.read(
          filteredEventsProvider(events: events),
        );

        // Only 'available' kept (eligibility ON → exclude 0-slot events)
        expect(result, hasLength(1));
        expect(result[0].id, 'available');
      },
    );

    test(
      'closingSoon without eligibility includes fully booked events',
      () {
        final events = [
          makeEvent(
            id: 'available',
            maxParticipants: 10,
            currentParticipants: 8,
          ),
          makeEvent(
            id: 'full',
            maxParticipants: 10,
            currentParticipants: 10,
          ),
        ];

        final container = createContainer();
        // Disable eligibility + nearby, enable closingSoon
        container.read(activeFiltersProvider.notifier).toggleEligibility();
        container.read(activeFiltersProvider.notifier).toggleNearby();
        container
            .read(activeFiltersProvider.notifier)
            .setSortType(ExploreSortType.closingSoon);

        final result = container.read(
          filteredEventsProvider(events: events),
        );

        // Both included, sorted by remaining slots ASC
        expect(result, hasLength(2));
        expect(result[0].id, 'full'); // 0 remaining
        expect(result[1].id, 'available'); // 2 remaining
      },
    );

    test('events with lat==0 lng==0 go to end of nearby sort', () async {
      final seoulLoc = makeLocation();
      final unknownLoc = makeLocation(lat: 0, lng: 0);

      final events = [
        makeEvent(id: 'unknown', location: unknownLoc),
        makeEvent(id: 'seoul', location: seoulLoc),
      ];

      final container = createContainer(
        overrides: [
          userLocationProvider.overrideWith(
            (ref) async => const LocationResult(
              latitude: 37.5665,
              longitude: 126.978,
            ),
          ),
        ],
      );

      // nearbyEnabled is true by default — no need to toggle
      await container.read(userLocationProvider.future);

      final result = container.read(
        filteredEventsProvider(events: events),
      );

      expect(result[0].id, 'seoul');
      expect(result[1].id, 'unknown');
    });
  });
}
