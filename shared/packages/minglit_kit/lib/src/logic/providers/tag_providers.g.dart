// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(featuredTags)
const featuredTagsProvider = FeaturedTagsProvider._();

final class FeaturedTagsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Tag>>,
          List<Tag>,
          FutureOr<List<Tag>>
        >
    with $FutureModifier<List<Tag>>, $FutureProvider<List<Tag>> {
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
  $FutureProviderElement<List<Tag>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Tag>> create(Ref ref) {
    return featuredTags(ref);
  }
}

String _$featuredTagsHash() => r'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b1';

@ProviderFor(trendingTags)
const trendingTagsProvider = TrendingTagsProvider._();

final class TrendingTagsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Tag>>,
          List<Tag>,
          FutureOr<List<Tag>>
        >
    with $FutureModifier<List<Tag>>, $FutureProvider<List<Tag>> {
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
  $FutureProviderElement<List<Tag>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Tag>> create(Ref ref) {
    return trendingTags(ref);
  }
}

String _$trendingTagsHash() => r'b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1';

@ProviderFor(tagSearch)
const tagSearchProvider = TagSearchFamily._();

final class TagSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Tag>>,
          List<Tag>,
          FutureOr<List<Tag>>
        >
    with $FutureModifier<List<Tag>>, $FutureProvider<List<Tag>> {
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
  $FutureProviderElement<List<Tag>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

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

String _$tagSearchHash() => r'c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2';

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

  TagSearchProvider call(String query) =>
      TagSearchProvider._(argument: query, from: this);

  @override
  String toString() => r'tagSearchProvider';
}

@ProviderFor(userInterestTags)
const userInterestTagsProvider = UserInterestTagsProvider._();

final class UserInterestTagsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Tag>>,
          List<Tag>,
          FutureOr<List<Tag>>
        >
    with $FutureModifier<List<Tag>>, $FutureProvider<List<Tag>> {
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
  $FutureProviderElement<List<Tag>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Tag>> create(Ref ref) {
    return userInterestTags(ref);
  }
}

String _$userInterestTagsHash() => r'd4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3';
