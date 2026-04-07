import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tag_selection_controller.g.dart';

/// 파티 생성/수정 위저드에서 태그 선택 상태를 관리한다.
///
/// 최대 5개 태그 제한을 강제하며, 위저드 컨트롤러에 변경 사항을 전파한다.
@riverpod
class TagSelectionController extends _$TagSelectionController {
  static const int maxTags = 5;

  @override
  List<Tag> build() => [];

  /// 태그를 선택 목록에 추가한다.
  ///
  /// 이미 선택된 태그이거나 최대 5개 제한에 도달하면 무시한다.
  void addTag(Tag tag) {
    if (state.length >= maxTags) return;
    if (state.any((t) => t.id == tag.id)) return;
    state = [...state, tag];
  }

  /// 태그 ID로 선택 목록에서 제거한다.
  void removeTag(String tagId) {
    state = state.where((t) => t.id != tagId).toList();
  }

  /// 선택된 태그를 모두 초기화한다.
  void clearTags() {
    state = [];
  }

  /// 태그 목록을 일괄 설정한다 (편집 모드에서 기존 태그 로드 시 사용).
  void setTags(List<Tag> tags) {
    state = tags.take(maxTags).toList();
  }

  /// 현재 선택된 태그 ID 목록을 반환한다.
  List<String> get tagIds => state.map((t) => t.id).toList();

  /// 최대 태그 수에 도달했는지 여부.
  bool get isMaxReached => state.length >= maxTags;
}
