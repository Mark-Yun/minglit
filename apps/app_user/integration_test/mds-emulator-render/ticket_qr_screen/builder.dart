import 'package:app_user/src/features/ticket/data/ticket_token_service.dart';
import 'package:app_user/src/features/ticket/ui/ticket_qr_screen.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../_engine/builder.dart';

class _MockTicketTokenService extends Mock implements TicketTokenService {}

TicketToken _fakeToken() => TicketToken(
  ticketId: 'ticket-render-001',
  eventId: 'event-render-001',
  userId: 'user-render-001',
  signature: 'sig-render-test-ok',
  expiresAt: DateTime(2099, 12, 31),
);

/// Builder for [TicketQRScreen] render catalog.
///
/// Default state: token present, no eventMeta (deep-link fallback path).
/// [notFound]: token null — renders error message.
class TicketQRScreenBuilder extends MdsScreenBuilder<TicketQRScreen> {
  TicketQRScreenBuilder()
    : _service = _MockTicketTokenService(),
      super(
        page: const TicketQRScreen(ticketId: 'ticket-render-001'),
        base: [],
      ) {
    when(() => _service.getToken(any())).thenAnswer((_) async => _fakeToken());
    addOverride(ticketTokenServiceProvider.overrideWith((_) => _service));
  }

  final _MockTicketTokenService _service;

  // Fix #2588: token null → renders "티켓 정보를 찾을 수 없습니다" error state.
  TicketQRScreenBuilder notFound() {
    when(() => _service.getToken(any())).thenAnswer((_) async => null);
    // ignore: avoid_returning_this, fluent builder — callers chain b.notFound().dark()
    return this;
  }

  TicketQRScreenBuilder dark() {
    useDarkTheme();
    // ignore: avoid_returning_this, fluent builder — callers chain b.notFound().dark()
    return this;
  }
}
