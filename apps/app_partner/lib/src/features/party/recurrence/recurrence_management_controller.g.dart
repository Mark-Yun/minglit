// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurrence_management_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// State for recurrence management operations.

@ProviderFor(RecurrenceManagementController)
const recurrenceManagementControllerProvider =
    RecurrenceManagementControllerProvider._();

/// State for recurrence management operations.
final class RecurrenceManagementControllerProvider
    extends $AsyncNotifierProvider<RecurrenceManagementController, void> {
  /// State for recurrence management operations.
  const RecurrenceManagementControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recurrenceManagementControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recurrenceManagementControllerHash();

  @$internal
  @override
  RecurrenceManagementController create() => RecurrenceManagementController();
}

String _$recurrenceManagementControllerHash() =>
    r'4eed2285d86acfad5f0696669f1c951d572655f4';

/// State for recurrence management operations.

abstract class _$RecurrenceManagementController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}

/// Fetches the active-or-paused recurrence rule for a party.
/// Returns null if no rule exists.

@ProviderFor(partyRecurrenceRule)
const partyRecurrenceRuleProvider = PartyRecurrenceRuleFamily._();

/// Fetches the active-or-paused recurrence rule for a party.
/// Returns null if no rule exists.

final class PartyRecurrenceRuleProvider
    extends
        $FunctionalProvider<
          AsyncValue<RecurrenceRule?>,
          RecurrenceRule?,
          FutureOr<RecurrenceRule?>
        >
    with $FutureModifier<RecurrenceRule?>, $FutureProvider<RecurrenceRule?> {
  /// Fetches the active-or-paused recurrence rule for a party.
  /// Returns null if no rule exists.
  const PartyRecurrenceRuleProvider._({
    required PartyRecurrenceRuleFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'partyRecurrenceRuleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$partyRecurrenceRuleHash();

  @override
  String toString() {
    return r'partyRecurrenceRuleProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<RecurrenceRule?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RecurrenceRule?> create(Ref ref) {
    final argument = this.argument as String;
    return partyRecurrenceRule(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PartyRecurrenceRuleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$partyRecurrenceRuleHash() =>
    r'c90fe085e7d3e676c889031b39d0ab671d9fb6f2';

/// Fetches the active-or-paused recurrence rule for a party.
/// Returns null if no rule exists.

final class PartyRecurrenceRuleFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<RecurrenceRule?>, String> {
  const PartyRecurrenceRuleFamily._()
    : super(
        retry: null,
        name: r'partyRecurrenceRuleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches the active-or-paused recurrence rule for a party.
  /// Returns null if no rule exists.

  PartyRecurrenceRuleProvider call(String partyId) =>
      PartyRecurrenceRuleProvider._(argument: partyId, from: this);

  @override
  String toString() => r'partyRecurrenceRuleProvider';
}
