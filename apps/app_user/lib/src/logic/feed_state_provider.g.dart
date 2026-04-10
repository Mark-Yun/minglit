// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SearchQuery)
const searchQueryProvider = SearchQueryProvider._();

final class SearchQueryProvider extends $NotifierProvider<SearchQuery, String> {
  const SearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchQueryHash();

  @$internal
  @override
  SearchQuery create() => SearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$searchQueryHash() => r'790bd96a8a13bb944767c7bf06a5378cfc78a54d';

abstract class _$SearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(ActiveFilters)
const activeFiltersProvider = ActiveFiltersProvider._();

final class ActiveFiltersProvider
    extends $NotifierProvider<ActiveFilters, ExploreFilters> {
  const ActiveFiltersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeFiltersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeFiltersHash();

  @$internal
  @override
  ActiveFilters create() => ActiveFilters();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExploreFilters value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExploreFilters>(value),
    );
  }
}

String _$activeFiltersHash() => r'1993d5e37e4b5d2a9f5cd1926fe7898bf17c757f';

abstract class _$ActiveFilters extends $Notifier<ExploreFilters> {
  ExploreFilters build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ExploreFilters, ExploreFilters>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ExploreFilters, ExploreFilters>,
              ExploreFilters,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(userLocation)
const userLocationProvider = UserLocationProvider._();

final class UserLocationProvider
    extends
        $FunctionalProvider<
          AsyncValue<LocationResult?>,
          LocationResult?,
          FutureOr<LocationResult?>
        >
    with $FutureModifier<LocationResult?>, $FutureProvider<LocationResult?> {
  const UserLocationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userLocationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userLocationHash();

  @$internal
  @override
  $FutureProviderElement<LocationResult?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LocationResult?> create(Ref ref) {
    return userLocation(ref);
  }
}

String _$userLocationHash() => r'c5abbab38df1a8f555fc8dfb49b489dbfeebed1a';

@ProviderFor(searchResults)
const searchResultsProvider = SearchResultsProvider._();

final class SearchResultsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          List<Event>,
          FutureOr<List<Event>>
        >
    with $FutureModifier<List<Event>>, $FutureProvider<List<Event>> {
  const SearchResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchResultsHash();

  @$internal
  @override
  $FutureProviderElement<List<Event>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Event>> create(Ref ref) {
    return searchResults(ref);
  }
}

String _$searchResultsHash() => r'1e0ac41dea7e827a16504833246fcec7a0728f68';

/// Fetches bulk eligibility data (user profile + verified status).

@ProviderFor(bulkEligibilityData)
const bulkEligibilityDataProvider = BulkEligibilityDataProvider._();

/// Fetches bulk eligibility data (user profile + verified status).

final class BulkEligibilityDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<BulkEligibilityData?>,
          BulkEligibilityData?,
          FutureOr<BulkEligibilityData?>
        >
    with
        $FutureModifier<BulkEligibilityData?>,
        $FutureProvider<BulkEligibilityData?> {
  /// Fetches bulk eligibility data (user profile + verified status).
  const BulkEligibilityDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bulkEligibilityDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bulkEligibilityDataHash();

  @$internal
  @override
  $FutureProviderElement<BulkEligibilityData?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<BulkEligibilityData?> create(Ref ref) {
    return bulkEligibilityData(ref);
  }
}

String _$bulkEligibilityDataHash() =>
    r'c4c2476bd082f1702a3351bb3225a8c46aad2837';

/// Applies active filters and nearby sort to a list of events (client-side).
///
/// Filter chain: eligibility (+ remaining-slots for closingSoon) → nearby sort
/// → closingSoon sort

@ProviderFor(filteredEvents)
const filteredEventsProvider = FilteredEventsFamily._();

/// Applies active filters and nearby sort to a list of events (client-side).
///
/// Filter chain: eligibility (+ remaining-slots for closingSoon) → nearby sort
/// → closingSoon sort

final class FilteredEventsProvider
    extends $FunctionalProvider<List<Event>, List<Event>, List<Event>>
    with $Provider<List<Event>> {
  /// Applies active filters and nearby sort to a list of events (client-side).
  ///
  /// Filter chain: eligibility (+ remaining-slots for closingSoon) → nearby sort
  /// → closingSoon sort
  const FilteredEventsProvider._({
    required FilteredEventsFamily super.from,
    required List<Event> super.argument,
  }) : super(
         retry: null,
         name: r'filteredEventsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filteredEventsHash();

  @override
  String toString() {
    return r'filteredEventsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<Event>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Event> create(Ref ref) {
    final argument = this.argument as List<Event>;
    return filteredEvents(ref, events: argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Event> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Event>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FilteredEventsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filteredEventsHash() => r'209203626d08e3f8d18f2d1266572654ad623169';

/// Applies active filters and nearby sort to a list of events (client-side).
///
/// Filter chain: eligibility (+ remaining-slots for closingSoon) → nearby sort
/// → closingSoon sort

final class FilteredEventsFamily extends $Family
    with $FunctionalFamilyOverride<List<Event>, List<Event>> {
  const FilteredEventsFamily._()
    : super(
        retry: null,
        name: r'filteredEventsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Applies active filters and nearby sort to a list of events (client-side).
  ///
  /// Filter chain: eligibility (+ remaining-slots for closingSoon) → nearby sort
  /// → closingSoon sort

  FilteredEventsProvider call({required List<Event> events}) =>
      FilteredEventsProvider._(argument: events, from: this);

  @override
  String toString() => r'filteredEventsProvider';
}

/// Manages pagination state for the recommendation event feed.
///
/// Tracks server-side offset separately from display count because
/// client-side filtering (eligibility + nearby sort) means the number
/// of displayed events may differ from the number fetched from server.
///
/// Filter changes (via [activeFiltersProvider]) automatically reset the
/// state to page 0.

@ProviderFor(RecommendationFeedNotifier)
const recommendationFeedProvider = RecommendationFeedNotifierProvider._();

/// Manages pagination state for the recommendation event feed.
///
/// Tracks server-side offset separately from display count because
/// client-side filtering (eligibility + nearby sort) means the number
/// of displayed events may differ from the number fetched from server.
///
/// Filter changes (via [activeFiltersProvider]) automatically reset the
/// state to page 0.
final class RecommendationFeedNotifierProvider
    extends
        $AsyncNotifierProvider<
          RecommendationFeedNotifier,
          RecommendationFeedState
        > {
  /// Manages pagination state for the recommendation event feed.
  ///
  /// Tracks server-side offset separately from display count because
  /// client-side filtering (eligibility + nearby sort) means the number
  /// of displayed events may differ from the number fetched from server.
  ///
  /// Filter changes (via [activeFiltersProvider]) automatically reset the
  /// state to page 0.
  const RecommendationFeedNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recommendationFeedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recommendationFeedNotifierHash();

  @$internal
  @override
  RecommendationFeedNotifier create() => RecommendationFeedNotifier();
}

String _$recommendationFeedNotifierHash() =>
    r'1e3980508ac3dc87a49d078d891b9ec3fbd35e99';

/// Manages pagination state for the recommendation event feed.
///
/// Tracks server-side offset separately from display count because
/// client-side filtering (eligibility + nearby sort) means the number
/// of displayed events may differ from the number fetched from server.
///
/// Filter changes (via [activeFiltersProvider]) automatically reset the
/// state to page 0.

abstract class _$RecommendationFeedNotifier
    extends $AsyncNotifier<RecommendationFeedState> {
  FutureOr<RecommendationFeedState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref
            as $Ref<
              AsyncValue<RecommendationFeedState>,
              RecommendationFeedState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<RecommendationFeedState>,
                RecommendationFeedState
              >,
              AsyncValue<RecommendationFeedState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Fetches and filters the unified recommendation event list.
///
/// Maps [ExploreSortType] to [EventFeedType]:
/// - recommended → newArrivals
/// - closingSoon → closingSoon
/// - nearestDate → nearest
///
// TODO: migrate to [recommendationEventsFromEf] once the user-event-feed EF
// is validated in production.

@ProviderFor(recommendationEvents)
const recommendationEventsProvider = RecommendationEventsProvider._();

/// Fetches and filters the unified recommendation event list.
///
/// Maps [ExploreSortType] to [EventFeedType]:
/// - recommended → newArrivals
/// - closingSoon → closingSoon
/// - nearestDate → nearest
///
// TODO: migrate to [recommendationEventsFromEf] once the user-event-feed EF
// is validated in production.

final class RecommendationEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          List<Event>,
          FutureOr<List<Event>>
        >
    with $FutureModifier<List<Event>>, $FutureProvider<List<Event>> {
  /// Fetches and filters the unified recommendation event list.
  ///
  /// Maps [ExploreSortType] to [EventFeedType]:
  /// - recommended → newArrivals
  /// - closingSoon → closingSoon
  /// - nearestDate → nearest
  ///
  // TODO: migrate to [recommendationEventsFromEf] once the user-event-feed EF
  // is validated in production.
  const RecommendationEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recommendationEventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recommendationEventsHash();

  @$internal
  @override
  $FutureProviderElement<List<Event>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Event>> create(Ref ref) {
    return recommendationEvents(ref);
  }
}

String _$recommendationEventsHash() =>
    r'6c45f80d337359eb151c3c2195073e6f785ad2ec';

/// Server-side feed via user-event-feed Edge Function (#614).
///
/// All sorting, filtering (block, eligibility, nearby, remaining slots),
/// and cursor pagination are handled by the DB function, so no
/// client-side post-processing is needed.
///
// TODO: wire this into the explore UI behind a feature flag, then remove the
// legacy [recommendationEvents] path.

@ProviderFor(recommendationEventsFromEf)
const recommendationEventsFromEfProvider =
    RecommendationEventsFromEfProvider._();

/// Server-side feed via user-event-feed Edge Function (#614).
///
/// All sorting, filtering (block, eligibility, nearby, remaining slots),
/// and cursor pagination are handled by the DB function, so no
/// client-side post-processing is needed.
///
// TODO: wire this into the explore UI behind a feature flag, then remove the
// legacy [recommendationEvents] path.

final class RecommendationEventsFromEfProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>>,
          Map<String, dynamic>,
          FutureOr<Map<String, dynamic>>
        >
    with
        $FutureModifier<Map<String, dynamic>>,
        $FutureProvider<Map<String, dynamic>> {
  /// Server-side feed via user-event-feed Edge Function (#614).
  ///
  /// All sorting, filtering (block, eligibility, nearby, remaining slots),
  /// and cursor pagination are handled by the DB function, so no
  /// client-side post-processing is needed.
  ///
  // TODO: wire this into the explore UI behind a feature flag, then remove the
  // legacy [recommendationEvents] path.
  const RecommendationEventsFromEfProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recommendationEventsFromEfProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recommendationEventsFromEfHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, dynamic>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>> create(Ref ref) {
    return recommendationEventsFromEf(ref);
  }
}

String _$recommendationEventsFromEfHash() =>
    r'4a6727075b5b43db880babbc5c5d8cad53f5bd2e';
