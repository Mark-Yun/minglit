// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AdminCoordinator)
const adminCoordinatorProvider = AdminCoordinatorProvider._();

final class AdminCoordinatorProvider
    extends $NotifierProvider<AdminCoordinator, void> {
  const AdminCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminCoordinatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminCoordinatorHash();

  @$internal
  @override
  AdminCoordinator create() => AdminCoordinator();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$adminCoordinatorHash() => r'bb36843134e78a9e38bf53894046519464b038c5';

abstract class _$AdminCoordinator extends $Notifier<void> {
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
