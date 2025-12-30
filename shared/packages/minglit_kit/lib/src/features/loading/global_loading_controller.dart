import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'global_loading_controller.freezed.dart';
part 'global_loading_controller.g.dart';

@freezed
abstract class GlobalLoadingState with _$GlobalLoadingState {
  const factory GlobalLoadingState({
    @Default(false) bool isVisible,
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
  @override
  GlobalLoadingState build() {
    return const GlobalLoadingState();
  }

  void show({VoidCallback? onCancel}) {
    state = GlobalLoadingState(isVisible: true, onCancel: onCancel);
  }

  void hide() {
    state = const GlobalLoadingState();
  }
}
