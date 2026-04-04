// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matching_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [MatchingRepository].

@ProviderFor(matchingRepository)
const matchingRepositoryProvider = MatchingRepositoryProvider._();

/// Provides the [MatchingRepository].

final class MatchingRepositoryProvider
    extends
        $FunctionalProvider<
          MatchingRepository,
          MatchingRepository,
          MatchingRepository
        >
    with $Provider<MatchingRepository> {
  /// Provides the [MatchingRepository].
  const MatchingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'matchingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$matchingRepositoryHash();

  @$internal
  @override
  $ProviderElement<MatchingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MatchingRepository create(Ref ref) {
    return matchingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MatchingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MatchingRepository>(value),
    );
  }
}

String _$matchingRepositoryHash() =>
    r'61950d7065db2a84d17f20777143e2418848fed6';

/// Fetches matching candidates for the current user in an event.

@ProviderFor(matchCandidates)
const matchCandidatesProvider = MatchCandidatesFamily._();

/// Fetches matching candidates for the current user in an event.

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
  /// Fetches matching candidates for the current user in an event.
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

/// Fetches matching candidates for the current user in an event.

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

  /// Fetches matching candidates for the current user in an event.

  MatchCandidatesProvider call(String eventId) =>
      MatchCandidatesProvider._(argument: eventId, from: this);

  @override
  String toString() => r'matchCandidatesProvider';
}

/// Fetches successful matches for the current user in an event.

@ProviderFor(myMatches)
const myMatchesProvider = MyMatchesFamily._();

/// Fetches successful matches for the current user in an event.

final class MyMatchesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MatchPair>>,
          List<MatchPair>,
          FutureOr<List<MatchPair>>
        >
    with $FutureModifier<List<MatchPair>>, $FutureProvider<List<MatchPair>> {
  /// Fetches successful matches for the current user in an event.
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

/// Fetches successful matches for the current user in an event.

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

  /// Fetches successful matches for the current user in an event.

  MyMatchesProvider call(String eventId) =>
      MyMatchesProvider._(argument: eventId, from: this);

  @override
  String toString() => r'myMatchesProvider';
}

/// Fetches the voter's current vote count for an event.

@ProviderFor(myVoteCount)
const myVoteCountProvider = MyVoteCountFamily._();

/// Fetches the voter's current vote count for an event.

final class MyVoteCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Fetches the voter's current vote count for an event.
  const MyVoteCountProvider._({
    required MyVoteCountFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'myVoteCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myVoteCountHash();

  @override
  String toString() {
    return r'myVoteCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as String;
    return myVoteCount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MyVoteCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myVoteCountHash() => r'c59ff09841424d7727c2428b7b95d69d8d6f8f38';

/// Fetches the voter's current vote count for an event.

final class MyVoteCountFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, String> {
  const MyVoteCountFamily._()
    : super(
        retry: null,
        name: r'myVoteCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches the voter's current vote count for an event.

  MyVoteCountProvider call(String eventId) =>
      MyVoteCountProvider._(argument: eventId, from: this);

  @override
  String toString() => r'myVoteCountProvider';
}

/// Fetches the voted candidate IDs for the current user in an event.

@ProviderFor(myVotedCandidateIds)
const myVotedCandidateIdsProvider = MyVotedCandidateIdsFamily._();

/// Fetches the voted candidate IDs for the current user in an event.

final class MyVotedCandidateIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          FutureOr<Set<String>>
        >
    with $FutureModifier<Set<String>>, $FutureProvider<Set<String>> {
  /// Fetches the voted candidate IDs for the current user in an event.
  const MyVotedCandidateIdsProvider._({
    required MyVotedCandidateIdsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'myVotedCandidateIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$myVotedCandidateIdsHash();

  @override
  String toString() {
    return r'myVotedCandidateIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Set<String>> create(Ref ref) {
    final argument = this.argument as String;
    return myVotedCandidateIds(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MyVotedCandidateIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myVotedCandidateIdsHash() =>
    r'c26471f0b1523dc1f4c56c9d9d6086bcd85a6acb';

/// Fetches the voted candidate IDs for the current user in an event.

final class MyVotedCandidateIdsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Set<String>>, String> {
  const MyVotedCandidateIdsFamily._()
    : super(
        retry: null,
        name: r'myVotedCandidateIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches the voted candidate IDs for the current user in an event.

  MyVotedCandidateIdsProvider call(String eventId) =>
      MyVotedCandidateIdsProvider._(argument: eventId, from: this);

  @override
  String toString() => r'myVotedCandidateIdsProvider';
}

/// Fetches the maximum vote count from matching rules for an event.

@ProviderFor(maxVoteCount)
const maxVoteCountProvider = MaxVoteCountFamily._();

/// Fetches the maximum vote count from matching rules for an event.

final class MaxVoteCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Fetches the maximum vote count from matching rules for an event.
  const MaxVoteCountProvider._({
    required MaxVoteCountFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'maxVoteCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$maxVoteCountHash();

  @override
  String toString() {
    return r'maxVoteCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as String;
    return maxVoteCount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MaxVoteCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$maxVoteCountHash() => r'3e5c192dc6847792a09e6db41136ad42f12ceca3';

/// Fetches the maximum vote count from matching rules for an event.

final class MaxVoteCountFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, String> {
  const MaxVoteCountFamily._()
    : super(
        retry: null,
        name: r'maxVoteCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches the maximum vote count from matching rules for an event.

  MaxVoteCountProvider call(String eventId) =>
      MaxVoteCountProvider._(argument: eventId, from: this);

  @override
  String toString() => r'maxVoteCountProvider';
}
