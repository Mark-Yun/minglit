// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_selection_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TagSelectionController)
const tagSelectionControllerProvider = TagSelectionControllerProvider._();

final class TagSelectionControllerProvider
    extends $NotifierProvider<TagSelectionController, List<Tag>> {
  const TagSelectionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagSelectionControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagSelectionControllerHash();

  @$internal
  @override
  TagSelectionController create() => TagSelectionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Tag> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Tag>>(value),
    );
  }
}

String _$tagSelectionControllerHash() =>
    r'f1e2d3c4b5a6f7e8d9c0b1a2f3e4d5c6b7a8f9e0';

abstract class _$TagSelectionController extends $Notifier<List<Tag>> {
  List<Tag> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<List<Tag>, List<Tag>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Tag>, List<Tag>>,
              List<Tag>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
