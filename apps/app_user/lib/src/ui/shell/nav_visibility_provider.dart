import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'nav_visibility_provider.g.dart';

/// Controls bottom navigation bar visibility.
///
/// `false` = hidden (initial state on app launch).
/// `true` = visible (shown on upward scroll in home tab).
///
/// Only the home tab (index == 0) drives this provider via scroll events.
/// The my-page tab always shows the nav bar regardless of this value.
@riverpod
class NavVisibility extends _$NavVisibility {
  @override
  bool build() => false;

  /// Show the bottom navigation bar.
  void show() => state = true;

  /// Hide the bottom navigation bar.
  void hide() => state = false;
}
