// MDS screen: event_application_review_confirm_page
// 대응 MDS: apps/mds/docs/public/specs/event_application_review_confirm_page/
//
// 출력: docs/infra/mds-emulator-render/event_application_review_confirm_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<EventApplicationReviewConfirmPageBuilder>(
  screen: 'event_application_review_confirm_page',
  mdsSpec: 'apps/mds/docs/public/specs/event_application_review_confirm_page/',
  builder: EventApplicationReviewConfirmPageBuilder.new,
  states: [
    MdsState('state-default', (b) => b.defaultState(), mdsIndex: 1),
    MdsState('state-submitting', (b) => b.defaultState(), mdsIndex: 2),
    MdsState('state-success', (b) => b.defaultState(), mdsIndex: 3),
    MdsState('state-error', (b) => b.defaultState(), mdsIndex: 4),
    MdsState('state-dark', (b) => b.dark(), mdsIndex: 5),
  ],
);

void main() => MdsRenderEngine.run(catalog);
