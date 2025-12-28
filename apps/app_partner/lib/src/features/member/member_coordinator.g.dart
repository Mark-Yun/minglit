// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MemberCoordinator)
const memberCoordinatorProvider = MemberCoordinatorProvider._();

final class MemberCoordinatorProvider
    extends $NotifierProvider<MemberCoordinator, void> {
  const MemberCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'memberCoordinatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$memberCoordinatorHash();

  @$internal
  @override
  MemberCoordinator create() => MemberCoordinator();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$memberCoordinatorHash() => r'a7f871a03426b93bdde7cba736aa4e6c15f692be';

abstract class _$MemberCoordinator extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
