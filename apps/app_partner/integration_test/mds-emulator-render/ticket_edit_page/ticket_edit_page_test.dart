// MDS screen: ticket_edit_page
// 대응 MDS: apps/mds/docs/public/specs/ticket_edit_page/
//
// 출력: docs/infra/mds-emulator-render/ticket_edit_page/state-*.png

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<TicketEditPageBuilder>(
  screen: 'ticket_edit_page',
  mdsSpec: 'apps/mds/docs/public/specs/ticket_edit_page/',
  builder: TicketEditPageBuilder.new,
  states: [
    MdsState('state-default', (b) => b.defaultState(), mdsIndex: 1),
  ],
);

void main() => MdsRenderEngine.run(catalog);
