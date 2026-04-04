// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurrence_rule_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recurrenceRuleRepository)
const recurrenceRuleRepositoryProvider = RecurrenceRuleRepositoryProvider._();

final class RecurrenceRuleRepositoryProvider
    extends
        $FunctionalProvider<
          RecurrenceRuleRepository,
          RecurrenceRuleRepository,
          RecurrenceRuleRepository
        >
    with $Provider<RecurrenceRuleRepository> {
  const RecurrenceRuleRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recurrenceRuleRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recurrenceRuleRepositoryHash();

  @$internal
  @override
  $ProviderElement<RecurrenceRuleRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RecurrenceRuleRepository create(Ref ref) {
    return recurrenceRuleRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RecurrenceRuleRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RecurrenceRuleRepository>(value),
    );
  }
}

String _$recurrenceRuleRepositoryHash() =>
    r'b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1';
