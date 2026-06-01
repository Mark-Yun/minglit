// MDS screen: event_application_review_carousel_page
// 대응 MDS: apps/mds/docs/public/specs/event_application_review_carousel_page/
//
// 출력: docs/infra/mds-emulator-render/event_application_review_carousel_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<EventApplicationReviewCarouselPageBuilder>(
  screen: 'event_application_review_carousel_page',
  mdsSpec: 'apps/mds/docs/public/specs/event_application_review_carousel_page/',
  builder: EventApplicationReviewCarouselPageBuilder.new,
  states: [
    MdsState('state-default', (b) => b.defaultState(), mdsIndex: 1),
    MdsState('state-first-page', (b) => b.defaultState(), mdsIndex: 2),
    MdsState('state-middle-page', (b) => b.defaultState(), mdsIndex: 3),
    MdsState('state-last-page', (b) => b.dark(), mdsIndex: 4),
  ],
);

void main() => MdsRenderEngine.run(catalog);
