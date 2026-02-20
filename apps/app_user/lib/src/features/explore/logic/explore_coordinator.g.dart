// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'explore_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(exploreCoordinator)
const exploreCoordinatorProvider = ExploreCoordinatorProvider._();

final class ExploreCoordinatorProvider
    extends
        $FunctionalProvider<
          ExploreCoordinator,
          ExploreCoordinator,
          ExploreCoordinator
        >
    with $Provider<ExploreCoordinator> {
  const ExploreCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exploreCoordinatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exploreCoordinatorHash();

  @$internal
  @override
  $ProviderElement<ExploreCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ExploreCoordinator create(Ref ref) {
    return exploreCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExploreCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExploreCoordinator>(value),
    );
  }
}

String _$exploreCoordinatorHash() =>
    r'4c9206decc775aca7f0629454743110c035d7590';
