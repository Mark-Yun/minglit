// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consent_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(consentCoordinator)
const consentCoordinatorProvider = ConsentCoordinatorProvider._();

final class ConsentCoordinatorProvider
    extends
        $FunctionalProvider<
          ConsentCoordinator,
          ConsentCoordinator,
          ConsentCoordinator
        >
    with $Provider<ConsentCoordinator> {
  const ConsentCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'consentCoordinatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$consentCoordinatorHash();

  @$internal
  @override
  $ProviderElement<ConsentCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ConsentCoordinator create(Ref ref) {
    return consentCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConsentCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConsentCoordinator>(value),
    );
  }
}

String _$consentCoordinatorHash() =>
    r'dd21c2be21667561d793275db6a2ea5df25c3163';
