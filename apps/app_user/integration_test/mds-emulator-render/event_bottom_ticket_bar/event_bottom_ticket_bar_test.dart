// MDS screen: event_bottom_ticket_bar
// 대응 MDS: apps/mds/docs/public/specs/event_bottom_ticket_bar/
//
// 출력: docs/infra/mds-emulator-render/event_bottom_ticket_bar/state-*.png
//
// Refs #2588: mds-render-coverage event-operation 카탈로그 등록

import '../_engine/catalog.dart';
import '../_engine/runner.dart';
import '../_engine/state.dart';
import 'builder.dart';

final catalog = MdsCatalog<EventBottomTicketBarBuilder>(
  screen: 'event_bottom_ticket_bar',
  mdsSpec: 'apps/mds/docs/public/specs/event_bottom_ticket_bar/',
  builder: EventBottomTicketBarBuilder.new,
  states: [
    // 12 admission states
    MdsState('state-eligible', (b) => b..eligible(), mdsIndex: 4),
    MdsState('state-guest', (b) => b..guest(), mdsIndex: 1),
    MdsState('state-identity-required', (b) => b..identityRequired(), mdsIndex: 2),
    MdsState(
      'state-qualification-required',
      (b) => b..qualificationRequired(),
      mdsIndex: 3,
    ),
    MdsState('state-not-eligible', (b) => b..notEligible(), mdsIndex: 5),
    MdsState('state-sold-out', (b) => b..soldOut(), mdsIndex: 6),
    MdsState('state-pending-payment', (b) => b..pendingPayment(), mdsIndex: 7),
    MdsState('state-applied', (b) => b..applied(), mdsIndex: 8),
    MdsState('state-rejected', (b) => b..rejected(), mdsIndex: 9),
    MdsState('state-event-ended', (b) => b..eventEnded(), mdsIndex: 10),
    MdsState(
      'state-event-ended-with-results',
      (b) => b..eventEndedWithResults(),
      mdsIndex: 11,
    ),
    MdsState(
      'state-event-ended-participated',
      (b) => b..eventEndedParticipated(),
      mdsIndex: 12,
    ),
    // Async states
    MdsState(
      'state-loading',
      (b) => b..loading(),
      mdsIndex: 13,
      infiniteAnimation: true,
    ),
    MdsState('state-error', (b) => b..error(), mdsIndex: 14),
    // Dark mode variant (메인 케이스)
    MdsState(
      'state-eligible-dark',
      (b) => b
        ..eligible()
        ..dark(),
    ),
  ],
);

void main() => MdsRenderEngine.run(catalog);
