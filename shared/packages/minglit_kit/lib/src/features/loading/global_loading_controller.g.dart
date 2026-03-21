// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'global_loading_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(GlobalLoadingController)
const globalLoadingControllerProvider = GlobalLoadingControllerProvider._();

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
final class GlobalLoadingControllerProvider
    extends $NotifierProvider<GlobalLoadingController, GlobalLoadingState> {
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
  const GlobalLoadingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'globalLoadingControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$globalLoadingControllerHash();

  @$internal
  @override
  GlobalLoadingController create() => GlobalLoadingController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GlobalLoadingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GlobalLoadingState>(value),
    );
  }
}

String _$globalLoadingControllerHash() =>
    r'55d7dbd234e7f92bfd5f3025b7a65a71fd106c17';

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

abstract class _$GlobalLoadingController extends $Notifier<GlobalLoadingState> {
  GlobalLoadingState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<GlobalLoadingState, GlobalLoadingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GlobalLoadingState, GlobalLoadingState>,
              GlobalLoadingState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
