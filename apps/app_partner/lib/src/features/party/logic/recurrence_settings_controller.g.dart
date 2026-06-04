// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurrence_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the recurrence settings UI state for the event creation flow.
///
/// The controller is scoped to the event-create screen via
/// [ProviderScope.overrides] or via its auto-dispose lifetime.
/// It computes preview dates without repository calls.

@ProviderFor(RecurrenceSettingsController)
const recurrenceSettingsControllerProvider =
    RecurrenceSettingsControllerProvider._();

/// Manages the recurrence settings UI state for the event creation flow.
///
/// The controller is scoped to the event-create screen via
/// [ProviderScope.overrides] or via its auto-dispose lifetime.
/// It computes preview dates without repository calls.
final class RecurrenceSettingsControllerProvider
    extends
        $NotifierProvider<
          RecurrenceSettingsController,
          RecurrenceSettingsState
        > {
  /// Manages the recurrence settings UI state for the event creation flow.
  ///
  /// The controller is scoped to the event-create screen via
  /// [ProviderScope.overrides] or via its auto-dispose lifetime.
  /// It computes preview dates without repository calls.
  const RecurrenceSettingsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recurrenceSettingsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recurrenceSettingsControllerHash();

  @$internal
  @override
  RecurrenceSettingsController create() => RecurrenceSettingsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecurrenceSettingsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecurrenceSettingsState>(value),
    );
  }
}

String _$recurrenceSettingsControllerHash() =>
    r'a6662b339468cfb12b5327f6d10898a9935a8edc';

/// Manages the recurrence settings UI state for the event creation flow.
///
/// The controller is scoped to the event-create screen via
/// [ProviderScope.overrides] or via its auto-dispose lifetime.
/// It computes preview dates without repository calls.

abstract class _$RecurrenceSettingsController
    extends $Notifier<RecurrenceSettingsState> {
  RecurrenceSettingsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<RecurrenceSettingsState, RecurrenceSettingsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RecurrenceSettingsState, RecurrenceSettingsState>,
              RecurrenceSettingsState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
