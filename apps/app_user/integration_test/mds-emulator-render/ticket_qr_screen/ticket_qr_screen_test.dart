// MDS screen: ticket_qr_screen
// 대응 MDS: apps/mds/docs/public/specs/ticket_qr_screen/
//
// 출력: docs/infra/mds-emulator-render/ticket_qr_screen/state-*.png
//
// 커버리지 (spec 5개 중 3개):
//   mdsIndex 1 (no-meta): state-with-token — token 있음, eventMeta null
//   mdsIndex 5 (not-found): state-not-found — token null
//   ※ mdsIndex 2 (with-meta): TicketQRScreen.eventMeta 가 생성자 파라미터로 주입되어
//      builder 패턴에서 fluent 변경 불가. eventMeta provider 화 시 커버 가능.
//   ※ mdsIndex 3 (loading), 4 (error): FutureProvider 과도 상태 — 정적 캡처 대상 아님.

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<TicketQRScreenBuilder>(
  screen: 'ticket_qr_screen',
  mdsSpec: 'apps/mds/docs/public/specs/ticket_qr_screen/',
  builder: TicketQRScreenBuilder.new,
  states: [
    MdsState(
      'state-with-token',
      (b) => b,
      mdsIndex: 1,
      infiniteAnimation: true,
    ),
    MdsState(
      'state-not-found',
      (b) => b.notFound(),
      mdsIndex: 5,
      infiniteAnimation: true,
    ),
    MdsState('state-dark', (b) => b.dark(), infiniteAnimation: true),
  ],
);

void main() => MdsRenderEngine.run(catalog);
