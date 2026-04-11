// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the list of featured tags.
///
/// Kept alive indefinitely — invalidate manually when stale.

@ProviderFor(featuredTags)
const featuredTagsProvider = FeaturedTagsProvider._();

/// Provides the list of featured tags.
///
/// Kept alive indefinitely — invalidate manually when stale.

final class FeaturedTagsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Tag>>,
          List<Tag>,
          FutureOr<List<Tag>>
        >
    with $FutureModifier<List<Tag>>, $FutureProvider<List<Tag>> {
  /// Provides the list of featured tags.
  ///
  /// Kept alive indefinitely — invalidate manually when stale.
  const FeaturedTagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'featuredTagsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$featuredTagsHash();

  @$internal
  @override
  $FutureProviderElement<List<Tag>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Tag>> create(Ref ref) {
    return featuredTags(ref);
  }
}

String _$featuredTagsHash() => r'1eeee57e5f19fa6119b2351782f5852a656669fd';

/// Provides the list of trending tags.
///
/// Kept alive indefinitely — invalidate manually when stale.

@ProviderFor(trendingTags)
const trendingTagsProvider = TrendingTagsProvider._();

/// Provides the list of trending tags.
///
/// Kept alive indefinitely — invalidate manually when stale.

final class TrendingTagsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Tag>>,
          List<Tag>,
          FutureOr<List<Tag>>
        >
    with $FutureModifier<List<Tag>>, $FutureProvider<List<Tag>> {
  /// Provides the list of trending tags.
  ///
  /// Kept alive indefinitely — invalidate manually when stale.
  const TrendingTagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trendingTagsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trendingTagsHash();

  @$internal
  @override
  $FutureProviderElement<List<Tag>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Tag>> create(Ref ref) {
    return trendingTags(ref);
  }
}

String _$trendingTagsHash() => r'6306cb019311da5aa5c335f57674d5c0013efa16';

/// Searches tags matching [query].
///
/// Empty query returns an empty list without calling the server.

@ProviderFor(tagSearch)
const tagSearchProvider = TagSearchFamily._();

/// Searches tags matching [query].
///
/// Empty query returns an empty list without calling the server.

final class TagSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Tag>>,
          List<Tag>,
          FutureOr<List<Tag>>
        >
    with $FutureModifier<List<Tag>>, $FutureProvider<List<Tag>> {
  /// Searches tags matching [query].
  ///
  /// Empty query returns an empty list without calling the server.
  const TagSearchProvider._({
    required TagSearchFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tagSearchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tagSearchHash();

  @override
  String toString() {
    return r'tagSearchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Tag>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Tag>> create(Ref ref) {
    final argument = this.argument as String;
    return tagSearch(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TagSearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tagSearchHash() => r'1d3a6617e00e7779eb319eadc34475c9d0c54424';

/// Searches tags matching [query].
///
/// Empty query returns an empty list without calling the server.

final class TagSearchFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Tag>>, String> {
  const TagSearchFamily._()
    : super(
        retry: null,
        name: r'tagSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Searches tags matching [query].
  ///
  /// Empty query returns an empty list without calling the server.

  TagSearchProvider call(String query) =>
      TagSearchProvider._(argument: query, from: this);

  @override
  String toString() => r'tagSearchProvider';
}

/// Provides the current user's interest tags.

@ProviderFor(userInterestTags)
const userInterestTagsProvider = UserInterestTagsProvider._();

/// Provides the current user's interest tags.

final class UserInterestTagsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Tag>>,
          List<Tag>,
          FutureOr<List<Tag>>
        >
    with $FutureModifier<List<Tag>>, $FutureProvider<List<Tag>> {
  /// Provides the current user's interest tags.
  const UserInterestTagsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userInterestTagsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userInterestTagsHash();

  @$internal
  @override
  $FutureProviderElement<List<Tag>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Tag>> create(Ref ref) {
    return userInterestTags(ref);
  }
}

String _$userInterestTagsHash() => r'626e159a409d3b7534382ef2557747aadbff998d';

/// Provides personalized event recommendations based on user interest tags.

@ProviderFor(tagRecommendationFeed)
const tagRecommendationFeedProvider = TagRecommendationFeedProvider._();

/// Provides personalized event recommendations based on user interest tags.

final class TagRecommendationFeedProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Event>>,
          List<Event>,
          FutureOr<List<Event>>
        >
    with $FutureModifier<List<Event>>, $FutureProvider<List<Event>> {
  /// Provides personalized event recommendations based on user interest tags.
  const TagRecommendationFeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagRecommendationFeedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagRecommendationFeedHash();

  @$internal
  @override
  $FutureProviderElement<List<Event>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Event>> create(Ref ref) {
    return tagRecommendationFeed(ref);
  }
}

String _$tagRecommendationFeedHash() =>
    r'cffac2fa4d8c9c7350deb8912d49a87a54dbb80a';
