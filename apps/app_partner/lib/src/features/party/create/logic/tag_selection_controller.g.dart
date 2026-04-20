// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_selection_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 파티 생성/수정 위저드에서 태그 선택 상태를 관리한다.
///
/// 최대 5개 태그 제한을 강제하며, 위저드 컨트롤러에 변경 사항을 전파한다.

@ProviderFor(TagSelectionController)
const tagSelectionControllerProvider = TagSelectionControllerProvider._();

/// 파티 생성/수정 위저드에서 태그 선택 상태를 관리한다.
///
/// 최대 5개 태그 제한을 강제하며, 위저드 컨트롤러에 변경 사항을 전파한다.
final class TagSelectionControllerProvider
    extends $NotifierProvider<TagSelectionController, List<Tag>> {
  /// 파티 생성/수정 위저드에서 태그 선택 상태를 관리한다.
  ///
  /// 최대 5개 태그 제한을 강제하며, 위저드 컨트롤러에 변경 사항을 전파한다.
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
    r'4352ee98ced9a835e82c2ac5dbacda379cf3877e';

/// 파티 생성/수정 위저드에서 태그 선택 상태를 관리한다.
///
/// 최대 5개 태그 제한을 강제하며, 위저드 컨트롤러에 변경 사항을 전파한다.

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
