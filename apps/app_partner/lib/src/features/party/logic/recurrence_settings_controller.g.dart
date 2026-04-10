// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurrence_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the recurrence settings UI state for the event creation flow.
///
/// The controller is scoped to the event-create screen via [ProviderScope.overrides]
/// or via its auto-dispose lifetime. It computes preview dates without any
/// repository calls — submission is handled by EventCreateController.submit.

@ProviderFor(RecurrenceSettingsController)
const recurrenceSettingsControllerProvider =
    RecurrenceSettingsControllerProvider._();

/// Manages the recurrence settings UI state for the event creation flow.
///
/// The controller is scoped to the event-create screen via [ProviderScope.overrides]
/// or via its auto-dispose lifetime. It computes preview dates without any
/// repository calls — submission is handled by EventCreateController.submit.
final class RecurrenceSettingsControllerProvider
    extends
        $NotifierProvider<
          RecurrenceSettingsController,
          RecurrenceSettingsState
        > {
  /// Manages the recurrence settings UI state for the event creation flow.
  ///
  /// The controller is scoped to the event-create screen via [ProviderScope.overrides]
  /// or via its auto-dispose lifetime. It computes preview dates without any
  /// repository calls — submission is handled by EventCreateController.submit.
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
    r'a5eebab1bdcdbdc9b821114f1677237e89c71239';

/// Manages the recurrence settings UI state for the event creation flow.
///
/// The controller is scoped to the event-create screen via [ProviderScope.overrides]
/// or via its auto-dispose lifetime. It computes preview dates without any
/// repository calls — submission is handled by EventCreateController.submit.

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
