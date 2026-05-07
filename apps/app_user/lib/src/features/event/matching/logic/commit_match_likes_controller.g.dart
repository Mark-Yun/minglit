// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commit_match_likes_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CommitMatchLikesController)
const commitMatchLikesControllerProvider =
    CommitMatchLikesControllerProvider._();

final class CommitMatchLikesControllerProvider
    extends $AsyncNotifierProvider<CommitMatchLikesController, void> {
  const CommitMatchLikesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'commitMatchLikesControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$commitMatchLikesControllerHash();

  @$internal
  @override
  CommitMatchLikesController create() => CommitMatchLikesController();
}

String _$commitMatchLikesControllerHash() =>
    r'8666aded9cae3e8f97a6f3b7b665cfaaf95ebf0d';

abstract class _$CommitMatchLikesController extends $AsyncNotifier<void> {
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
