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
    r'd8e9a320d2c6aab18b45a273e2d40edb324508bb';

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
