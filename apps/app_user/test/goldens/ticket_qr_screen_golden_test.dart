@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:app_user/src/features/ticket/data/ticket_wallet_repository.dart';
import 'package:app_user/src/features/ticket/ui/ticket_qr_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import 'golden_test_helpers.dart';

class _MockTicketWalletRepository extends Mock
    implements TicketWalletRepository {}

void main() {
  late _MockTicketWalletRepository mockWalletRepository;
  final now = DateTime(2026, 4, 1, 12);
  final token = TicketToken(
    ticketId: 'ticket-1',
    eventId: 'event-1',
    userId: 'user-1',
    signature: 'signed-token',
    expiresAt: now.add(const Duration(hours: 3)),
  );

  setUpAll(() async {
    await initGoldenDeps();
  });

  setUp(() {
    mockWalletRepository = _MockTicketWalletRepository();
  });

  goldenTest(
    'TicketQRScreen with valid ticket token',
    fileName: 'ticket_qr_screen_valid',
    pumpBeforeTest: (tester) async {
      await tester.pump(const Duration(milliseconds: 300));
    },
    builder: () {
      when(
        () => mockWalletRepository.getTicket('ticket-1'),
      ).thenAnswer((_) async => token);

      return GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(400),
        children: [
          GoldenTestScenario(
            name: 'valid ticket',
            child: SizedBox(
              width: 390,
              height: 844,
              child: GoldenPageWrapper(
                page: const TicketQRScreen(ticketId: 'ticket-1'),
                overrides: [
                  ticketWalletRepositoryProvider.overrideWithValue(
                    mockWalletRepository,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );

  goldenTest(
    'TicketQRScreen missing ticket token',
    fileName: 'ticket_qr_screen_missing',
    pumpBeforeTest: (tester) async {
      await tester.pump(const Duration(milliseconds: 300));
    },
    builder: () {
      when(
        () => mockWalletRepository.getTicket('missing-ticket'),
      ).thenAnswer((_) async => null);

      return GoldenTestGroup(
        columnWidthBuilder: (_) => const FixedColumnWidth(400),
        children: [
          GoldenTestScenario(
            name: 'missing ticket',
            child: SizedBox(
              width: 390,
              height: 844,
              child: GoldenPageWrapper(
                page: const TicketQRScreen(ticketId: 'missing-ticket'),
                brightness: Brightness.dark,
                overrides: [
                  ticketWalletRepositoryProvider.overrideWithValue(
                    mockWalletRepository,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}
