import 'package:app_user/src/features/ticket/data/ticket_wallet_repository.dart';
import 'package:app_user/src/features/ticket/ui/model/ticket_event_meta.dart';
import 'package:app_user/src/features/ticket/ui/ticket_qr_screen.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import 'screenshot_scenario.dart';

class _MockTicketWalletRepository extends Mock
    implements TicketWalletRepository {}

class TicketQRScenarios {
  static final _now = DateTime(2026, 4, 1, 12);

  static TicketToken get _token => TicketToken(
    ticketId: 'ticket-1',
    eventId: 'event-1',
    userId: 'user-1',
    signature: 'signed-token',
    expiresAt: _now.add(const Duration(hours: 3)),
  );

  // Fix #1526: TicketEventMeta 추가 — 보딩패스 이벤트 정보 표시
  static TicketEventMeta get _eventMeta => TicketEventMeta(
    eventTitle: '봄밤 와인 테이스팅',
    // Future event → CONFIRMED badge
    eventDateTime: _now.add(const Duration(days: 5)),
    eventVenue: '강남 라운지바',
    ticketName: '일반 입장권',
  );

  static List<dynamic> _validOverrides() {
    final mockRepo = _MockTicketWalletRepository();
    when(() => mockRepo.getTicket('ticket-1')).thenAnswer((_) async => _token);
    return [ticketWalletRepositoryProvider.overrideWithValue(mockRepo)];
  }

  static List<dynamic> _missingOverrides() {
    final mockRepo = _MockTicketWalletRepository();
    when(
      () => mockRepo.getTicket('missing-ticket'),
    ).thenAnswer((_) async => null);
    return [ticketWalletRepositoryProvider.overrideWithValue(mockRepo)];
  }

  static List<ScreenshotScenario> get all => [
    ScreenshotScenario(
      name: 'ticket_qr_screen_valid',
      page: TicketQRScreen(ticketId: 'ticket-1', eventMeta: _eventMeta),
      overrides: _validOverrides(),
    ),
    ScreenshotScenario(
      name: 'ticket_qr_screen_missing',
      page: const TicketQRScreen(ticketId: 'missing-ticket'),
      brightness: Brightness.dark,
      overrides: _missingOverrides(),
    ),
  ];
}
