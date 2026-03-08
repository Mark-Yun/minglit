// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matching_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MatchingController)
const matchingControllerProvider = MatchingControllerProvider._();

final class MatchingControllerProvider
    extends $AsyncNotifierProvider<MatchingController, void> {
  const MatchingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'matchingControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$matchingControllerHash();

  @$internal
  @override
  MatchingController create() => MatchingController();
}

String _$matchingControllerHash() =>
    r'57fdb1abe9eb6fb3cbdd65ab2b230b5cb0dce04d';

abstract class _$MatchingController extends $AsyncNotifier<void> {
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

@ProviderFor(eventMatchRules)
const eventMatchRulesProvider = EventMatchRulesFamily._();

final class EventMatchRulesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MatchRule>>,
          List<MatchRule>,
          FutureOr<List<MatchRule>>
        >
    with $FutureModifier<List<MatchRule>>, $FutureProvider<List<MatchRule>> {
  const EventMatchRulesProvider._({
    required EventMatchRulesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'eventMatchRulesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$eventMatchRulesHash();

  @override
  String toString() {
    return r'eventMatchRulesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<MatchRule>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MatchRule>> create(Ref ref) {
    final argument = this.argument as String;
    return eventMatchRules(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EventMatchRulesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventMatchRulesHash() => r'73e9f0ef77bca0480841b0c08ba99487560b7b34';

final class EventMatchRulesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<MatchRule>>, String> {
  const EventMatchRulesFamily._()
    : super(
        retry: null,
        name: r'eventMatchRulesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EventMatchRulesProvider call(String eventId) =>
      EventMatchRulesProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventMatchRulesProvider';
}
