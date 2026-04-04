// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurrence_settings_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RecurrenceSettingsController)
const recurrenceSettingsControllerProvider =
    RecurrenceSettingsControllerProvider._();

final class RecurrenceSettingsControllerProvider
    extends
        $NotifierProvider<
          RecurrenceSettingsController,
          RecurrenceSettingsState
        > {
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
    r'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0';

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
