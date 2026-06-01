// TagEventListPageBuilder — tag_event_list_page 전용 fluent API.

import 'dart:async';

import 'package:app_user/src/features/tag/logic/tag_event_list_controller.dart';
import 'package:app_user/src/features/tag/ui/tag_event_list_page.dart';
import 'package:app_user/src/logic/event_coordinator.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/builder.dart';
import '../_mocks/coordinators.dart';

class _FixedTagEventListController extends TagEventListController {
  _FixedTagEventListController(this._state);
  final TagEventListState _state;

  @override
  Future<TagEventListState> build(String tagId) async => _state;
}

class _LoadingTagEventListController extends TagEventListController {
  @override
  Future<TagEventListState> build(String tagId) =>
      Completer<TagEventListState>().future;
}

class _ErrorTagEventListController extends TagEventListController {
  @override
  Future<TagEventListState> build(String tagId) async =>
      throw Exception('render: forced error');
}

final _base = DateTime(2026, 5, 18, 18);
const _tagId = 'tag-wine';

Event _event({
  required String id,
  required String title,
  required DateTime start,
}) {
  return Event(
    id: id,
    partyId: 'party-$id',
    title: title,
    startTime: start,
    endTime: start.add(const Duration(hours: 2)),
    createdAt: _base,
    updatedAt: _base,
  );
}

final _events = <Event>[
  _event(
    id: 'event-1',
    title: '와인 소셜 나이트',
    start: _base.add(const Duration(days: 1)),
  ),
  _event(
    id: 'event-2',
    title: '강남 밍글 라운지',
    start: _base.add(const Duration(days: 2)),
  ),
  _event(
    id: 'event-3',
    title: '홍대 위켄드 믹서',
    start: _base.add(const Duration(days: 3)),
  ),
];

class TagEventListPageBuilder extends MdsScreenBuilder<TagEventListPage> {
  TagEventListPageBuilder()
    : super(
        page: const TagEventListPage(tagId: _tagId, tagName: '와인'),
        base: [
          eventCoordinatorProvider.overrideWithValue(MockEventCoordinator()),
        ],
      );

  /// 기본 상태: 이벤트 목록이 로드되어 카드가 렌더됨.
  void withDefaultList() {
    addOverride(
      tagEventListControllerProvider(_tagId).overrideWith(
        () => _FixedTagEventListController(
          TagEventListState(
            events: _events,
          ),
        ),
      ),
    );
  }

  /// 빈 상태.
  void withEmpty() {
    addOverride(
      tagEventListControllerProvider(_tagId).overrideWith(
        () => _FixedTagEventListController(
          const TagEventListState(
            hasMore: false,
          ),
        ),
      ),
    );
  }

  /// 로딩 상태.
  void withLoading() {
    addOverride(
      tagEventListControllerProvider(_tagId).overrideWith(
        _LoadingTagEventListController.new,
      ),
    );
  }

  /// 에러 상태.
  void withError() {
    addOverride(
      tagEventListControllerProvider(_tagId).overrideWith(
        _ErrorTagEventListController.new,
      ),
    );
  }
}
