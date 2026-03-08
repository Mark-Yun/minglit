// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matching_vote_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MatchingVoteController)
const matchingVoteControllerProvider = MatchingVoteControllerProvider._();

final class MatchingVoteControllerProvider
    extends $AsyncNotifierProvider<MatchingVoteController, void> {
  const MatchingVoteControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'matchingVoteControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$matchingVoteControllerHash();

  @$internal
  @override
  MatchingVoteController create() => MatchingVoteController();
}

String _$matchingVoteControllerHash() =>
    r'7089846363640118c3ced43940bcfd60a096c8e2';

abstract class _$MatchingVoteController extends $AsyncNotifier<void> {
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

@ProviderFor(matchCandidates)
const matchCandidatesProvider = MatchCandidatesFamily._();

final class MatchCandidatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UserProfile>>,
          List<UserProfile>,
          FutureOr<List<UserProfile>>
        >
    with
        $FutureModifier<List<UserProfile>>,
        $FutureProvider<List<UserProfile>> {
  const MatchCandidatesProvider._({
    required MatchCandidatesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'matchCandidatesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$matchCandidatesHash();

  @override
  String toString() {
    return r'matchCandidatesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<UserProfile>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<UserProfile>> create(Ref ref) {
    final argument = this.argument as String;
    return matchCandidates(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MatchCandidatesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$matchCandidatesHash() => r'c7ada3a4f5892dad45787e78a963feff15a39542';

final class MatchCandidatesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<UserProfile>>, String> {
  const MatchCandidatesFamily._()
    : super(
        retry: null,
        name: r'matchCandidatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MatchCandidatesProvider call(String eventId) =>
      MatchCandidatesProvider._(argument: eventId, from: this);

  @override
  String toString() => r'matchCandidatesProvider';
}

@ProviderFor(myMatches)
const myMatchesProvider = MyMatchesFamily._();

final class MyMatchesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MatchPair>>,
          List<MatchPair>,
          FutureOr<List<MatchPair>>
        >
    with $FutureModifier<List<MatchPair>>, $FutureProvider<List<MatchPair>> {
  const MyMatchesProvider._({
    required MyMatchesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'myMatchesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myMatchesHash();

  @override
  String toString() {
    return r'myMatchesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<MatchPair>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MatchPair>> create(Ref ref) {
    final argument = this.argument as String;
    return myMatches(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MyMatchesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myMatchesHash() => r'4a5e9634d05797acaedf3e500e863a62aa74c2f3';

final class MyMatchesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<MatchPair>>, String> {
  const MyMatchesFamily._()
    : super(
        retry: null,
        name: r'myMatchesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MyMatchesProvider call(String eventId) =>
      MyMatchesProvider._(argument: eventId, from: this);

  @override
  String toString() => r'myMatchesProvider';
}
