// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VerificationCoordinator)
const verificationCoordinatorProvider = VerificationCoordinatorProvider._();

final class VerificationCoordinatorProvider
    extends $NotifierProvider<VerificationCoordinator, void> {
  const VerificationCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verificationCoordinatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verificationCoordinatorHash();

  @$internal
  @override
  VerificationCoordinator create() => VerificationCoordinator();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$verificationCoordinatorHash() =>
    r'fdc9a88a64be08a3edcc19ae19f0d0d0364ad4b7';

abstract class _$VerificationCoordinator extends $Notifier<void> {
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
