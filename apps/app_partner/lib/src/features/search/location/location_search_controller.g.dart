// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_search_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LocationSearchController)
const locationSearchControllerProvider = LocationSearchControllerProvider._();

final class LocationSearchControllerProvider
    extends $AsyncNotifierProvider<LocationSearchController, List<Location>> {
  const LocationSearchControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationSearchControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationSearchControllerHash();

  @$internal
  @override
  LocationSearchController create() => LocationSearchController();
}

String _$locationSearchControllerHash() =>
    r'01fe09ba8149eba5f8e14b8208b799220114e720';

abstract class _$LocationSearchController
    extends $AsyncNotifier<List<Location>> {
  FutureOr<List<Location>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Location>>, List<Location>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Location>>, List<Location>>,
              AsyncValue<List<Location>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
