// MDS screen: event_card
// 대응 MDS: apps/mds/docs/public/specs/event_card/
//
// 출력: docs/infra/mds-emulator-render/event_card/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<EventCardBuilder>(
  screen: 'event_card',
  mdsSpec: 'apps/mds/docs/public/specs/event_card/',
  builder: EventCardBuilder.new,
  states: [
    MdsState('state-normal', (b) => b..normal(), mdsIndex: 1),
    MdsState('state-today', (b) => b..today(), mdsIndex: 2),
    MdsState('state-sold-out', (b) => b..soldOut(), mdsIndex: 3),
    MdsState('state-ended', (b) => b..ended(), mdsIndex: 4),
  ],
);

void main() => MdsRenderEngine.run(catalog);
