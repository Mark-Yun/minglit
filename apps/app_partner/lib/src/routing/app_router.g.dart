// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// **Centralized Router Provider**
///
/// Configures [GoRouter] with:
/// 1. **Initial Location**: Default entry point (`/`).
/// 2. **Refresh Logic**: Listens to [authStateChangesProvider] to auto-redirect on login/logout.
/// 3. **Redirect Logic**: Enforces authentication policy (Guest -> Login).
/// 4. **Routes**: Uses Type-safe routes from [app_routes.dart].

@ProviderFor(goRouter)
const goRouterProvider = GoRouterProvider._();

/// **Centralized Router Provider**
///
/// Configures [GoRouter] with:
/// 1. **Initial Location**: Default entry point (`/`).
/// 2. **Refresh Logic**: Listens to [authStateChangesProvider] to auto-redirect on login/logout.
/// 3. **Redirect Logic**: Enforces authentication policy (Guest -> Login).
/// 4. **Routes**: Uses Type-safe routes from [app_routes.dart].

final class GoRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// **Centralized Router Provider**
  ///
  /// Configures [GoRouter] with:
  /// 1. **Initial Location**: Default entry point (`/`).
  /// 2. **Refresh Logic**: Listens to [authStateChangesProvider] to auto-redirect on login/logout.
  /// 3. **Redirect Logic**: Enforces authentication policy (Guest -> Login).
  /// 4. **Routes**: Uses Type-safe routes from [app_routes.dart].
  const GoRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goRouterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return goRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$goRouterHash() => r'4f8ae10b160a81a1f2fd3edb9f92fe912e996b73';
