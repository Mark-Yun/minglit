import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'global_loading_controller.freezed.dart';
part 'global_loading_controller.g.dart';

/// Represents the global loading overlay state.
@freezed
abstract class GlobalLoadingState with _$GlobalLoadingState {
  /// Creates a loading state value.
  const factory GlobalLoadingState({
    /// Whether the overlay is visible.
    @Default(false) bool isVisible,

    /// Optional callback invoked when the user cancels.
    VoidCallback? onCancel,
  }) = _GlobalLoadingState;
}

/// **Global Loading Controller**
///
/// Manages the visibility of the global loading overlay.
/// Use `show` to block user interaction with a loading indicator.
/// Provide an `onCancel` callback to allow user cancellation (Back button).
/// Use `hide` to restore interaction.
///
/// **Usage:**
/// ```dart
/// ref.read(globalLoadingControllerProvider.notifier).show(
///   onCancel: () {
///     // Cancel async operation
///   },
/// );
/// ```
@Riverpod(keepAlive: true)
class GlobalLoadingController extends _$GlobalLoadingController {
  /// Builds the initial loading state.
  @override
  GlobalLoadingState build() {
    return const GlobalLoadingState();
  }

  /// Shows the global loading overlay.
  void show({VoidCallback? onCancel}) {
    state = GlobalLoadingState(isVisible: true, onCancel: onCancel);
  }

  /// Hides the global loading overlay.
  void hide() {
    state = const GlobalLoadingState();
  }
}
