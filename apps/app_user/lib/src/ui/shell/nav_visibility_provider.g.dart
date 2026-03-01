// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nav_visibility_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controls bottom navigation bar visibility.
///
/// `false` = hidden (initial state on app launch).
/// `true` = visible (shown on upward scroll in home tab).
///
/// Only the home tab (index == 0) drives this provider via scroll events.
/// The my-page tab always shows the nav bar regardless of this value.

@ProviderFor(NavVisibility)
const navVisibilityProvider = NavVisibilityProvider._();

/// Controls bottom navigation bar visibility.
///
/// `false` = hidden (initial state on app launch).
/// `true` = visible (shown on upward scroll in home tab).
///
/// Only the home tab (index == 0) drives this provider via scroll events.
/// The my-page tab always shows the nav bar regardless of this value.
final class NavVisibilityProvider
    extends $NotifierProvider<NavVisibility, bool> {
  /// Controls bottom navigation bar visibility.
  ///
  /// `false` = hidden (initial state on app launch).
  /// `true` = visible (shown on upward scroll in home tab).
  ///
  /// Only the home tab (index == 0) drives this provider via scroll events.
  /// The my-page tab always shows the nav bar regardless of this value.
  const NavVisibilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'navVisibilityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$navVisibilityHash();

  @$internal
  @override
  NavVisibility create() => NavVisibility();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$navVisibilityHash() => r'a9c4612d1c3dd086b17880f8bed5f5389961c0c1';

/// Controls bottom navigation bar visibility.
///
/// `false` = hidden (initial state on app launch).
/// `true` = visible (shown on upward scroll in home tab).
///
/// Only the home tab (index == 0) drives this provider via scroll events.
/// The my-page tab always shows the nav bar regardless of this value.

abstract class _$NavVisibility extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
