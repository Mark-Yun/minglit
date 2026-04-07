// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_event_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(TagEventListController)
const tagEventListControllerProvider = TagEventListControllerFamily._();

final class TagEventListControllerProvider
    extends $AsyncNotifierProvider<TagEventListController, TagEventListState> {
  const TagEventListControllerProvider._({
    required TagEventListControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tagEventListControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tagEventListControllerHash();

  @override
  String toString() {
    return r'tagEventListControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TagEventListController create() => TagEventListController();

  @override
  bool operator ==(Object other) {
    return other is TagEventListControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tagEventListControllerHash() =>
    r'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0';

final class TagEventListControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          TagEventListController,
          AsyncValue<TagEventListState>,
          TagEventListState,
          FutureOr<TagEventListState>,
          String
        > {
  const TagEventListControllerFamily._()
    : super(
        retry: null,
        name: r'tagEventListControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TagEventListControllerProvider call(String tagId) =>
      TagEventListControllerProvider._(argument: tagId, from: this);

  @override
  String toString() => r'tagEventListControllerProvider';
}

abstract class _$TagEventListController
    extends $AsyncNotifier<TagEventListState> {
  late final _$args = ref.$arg as String;
  String get tagId => _$args;

  FutureOr<TagEventListState> build(String tagId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref as $Ref<AsyncValue<TagEventListState>, TagEventListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TagEventListState>, TagEventListState>,
              AsyncValue<TagEventListState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
