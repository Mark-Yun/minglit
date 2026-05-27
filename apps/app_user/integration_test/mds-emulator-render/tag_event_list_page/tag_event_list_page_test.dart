// MDS screen: tag_event_list_page
// 대응 MDS: apps/mds/docs/public/specs/tag_event_list_page/
//
// 출력: docs/infra/mds-emulator-render/tag_event_list_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<TagEventListPageBuilder>(
  screen: 'tag_event_list_page',
  mdsSpec: 'apps/mds/docs/public/specs/tag_event_list_page/',
  builder: TagEventListPageBuilder.new,
  states: [
    MdsState(
      'state-default',
      (b) {
        b.withDefaultList();
        return b;
      },
      mdsIndex: 1,
    ),
    MdsState(
      'state-empty',
      (b) {
        b.withEmpty();
        return b;
      },
      mdsIndex: 2,
    ),
    MdsState(
      'state-loading',
      (b) {
        b.withLoading();
        return b;
      },
      mdsIndex: 3,
      infiniteAnimation: true,
    ),
    MdsState(
      'state-error',
      (b) {
        b.withError();
        return b;
      },
      mdsIndex: 4,
    ),
  ],
);

void main() => MdsRenderEngine.run(catalog);
