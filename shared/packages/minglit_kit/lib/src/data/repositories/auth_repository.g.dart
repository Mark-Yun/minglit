// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for AuthConfig. Must be overridden in main.dart.

@ProviderFor(authConfig)
const authConfigProvider = AuthConfigProvider._();

/// Provider for AuthConfig. Must be overridden in main.dart.

final class AuthConfigProvider
    extends $FunctionalProvider<AuthConfig, AuthConfig, AuthConfig>
    with $Provider<AuthConfig> {
  /// Provider for AuthConfig. Must be overridden in main.dart.
  const AuthConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authConfigHash();

  @$internal
  @override
  $ProviderElement<AuthConfig> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthConfig create(Ref ref) {
    return authConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthConfig>(value),
    );
  }
}

String _$authConfigHash() => r'48a07906efc566424427b55d54d81d7ccd40d96e';

/// Provider for the AuthRepository instance.

@ProviderFor(authRepository)
const authRepositoryProvider = AuthRepositoryProvider._();

/// Provider for the AuthRepository instance.

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  /// Provider for the AuthRepository instance.
  const AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'47b91d6dad241ba42aefd4bb581bbed093f6dba7';

/// Provider for authentication state changes stream.

@ProviderFor(authStateChanges)
const authStateChangesProvider = AuthStateChangesProvider._();

/// Provider for authentication state changes stream.

final class AuthStateChangesProvider
    extends
        $FunctionalProvider<AsyncValue<AuthState>, AuthState, Stream<AuthState>>
    with $FutureModifier<AuthState>, $StreamProvider<AuthState> {
  /// Provider for authentication state changes stream.
  const AuthStateChangesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateChangesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateChangesHash();

  @$internal
  @override
  $StreamProviderElement<AuthState> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<AuthState> create(Ref ref) {
    return authStateChanges(ref);
  }
}

String _$authStateChangesHash() => r'bd8ae3d3636b6ce8ce4fe4de396bc5acac533b44';

/// Provider for the current user. Updates automatically on auth state change.

@ProviderFor(currentUser)
const currentUserProvider = CurrentUserProvider._();

/// Provider for the current user. Updates automatically on auth state change.

final class CurrentUserProvider extends $FunctionalProvider<User?, User?, User?>
    with $Provider<User?> {
  /// Provider for the current user. Updates automatically on auth state change.
  const CurrentUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserHash();

  @$internal
  @override
  $ProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  User? create(Ref ref) {
    return currentUser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(User? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<User?>(value),
    );
  }
}

String _$currentUserHash() => r'f6d334bea51c925e5ec24c3015f24f86dec6f1cc';
