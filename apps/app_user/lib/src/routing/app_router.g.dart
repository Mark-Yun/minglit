// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// **User App Router**
///
/// Handles navigation and redirects for the User Application.
///
/// **Policy:**
/// - Guests are redirected to `/login`.
/// - Logged-in users trying to access `/login` are redirected to `/`.

@ProviderFor(goRouter)
const goRouterProvider = GoRouterProvider._();

/// **User App Router**
///
/// Handles navigation and redirects for the User Application.
///
/// **Policy:**
/// - Guests are redirected to `/login`.
/// - Logged-in users trying to access `/login` are redirected to `/`.

final class GoRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// **User App Router**
  ///
  /// Handles navigation and redirects for the User Application.
  ///
  /// **Policy:**
  /// - Guests are redirected to `/login`.
  /// - Logged-in users trying to access `/login` are redirected to `/`.
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
