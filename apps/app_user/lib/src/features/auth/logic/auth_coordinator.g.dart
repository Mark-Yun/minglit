// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authCoordinator)
const authCoordinatorProvider = AuthCoordinatorProvider._();

final class AuthCoordinatorProvider
    extends
        $FunctionalProvider<AuthCoordinator, AuthCoordinator, AuthCoordinator>
    with $Provider<AuthCoordinator> {
  const AuthCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authCoordinatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authCoordinatorHash();

  @$internal
  @override
  $ProviderElement<AuthCoordinator> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthCoordinator create(Ref ref) {
    return authCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthCoordinator>(value),
    );
  }
}

String _$authCoordinatorHash() => r'6fd827ba5d5beca3d502ed21e34c9d84ee4daec8';
