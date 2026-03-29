import 'dart:async';

import 'package:app_user/src/features/home/widgets/event_now_bar_controller.dart';
import 'package:app_user/src/features/home/widgets/event_now_bottom_sheet.dart';
import 'package:app_user/src/features/ticket/data/ticket_wallet_repository.dart';
import 'package:app_user/src/features/ticket/ui/widgets/ticket_qr_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';

class MockTicketWalletRepository extends Mock
    implements TicketWalletRepository {}

void main() {
  late MockMatchingRepository mockMatchingRepo;
  late MockTicketWalletRepository mockWallet;

  final now = DateTime(2026, 3, 30, 15);

  final testToken = TicketToken(
    ticketId: 'ticket_1',
    eventId: 'event_1',
    userId: 'user_123',
    signature: 'test_sig',
    expiresAt: now.add(const Duration(days: 7)),
  );

  final testLocation = Location(
    id: 'loc_1',
    partnerId: 'partner_1',
    name: '강남 라운지',
    address: '서울시 강남구 테헤란로 123',
    createdAt: now,
    updatedAt: now,
    latitude: 37.5015,
    longitude: 127.0397,
  );

  final testParty = Party(
    id: 'party_1',
    partnerId: 'partner_1',
    title: '밍릿 파티',
    createdAt: now,
    updatedAt: now,
    location: testLocation,
  );

  setUp(() {
    mockMatchingRepo = MockMatchingRepository();
    mockWallet = MockTicketWalletRepository();
  });

  TodayActiveEvent makeActiveEvent({
    String id = 'event_1',
    String title = '강남 밍릿파티',
    String status = 'scheduled',
    String participantStatus = 'ticket_issued',
    DateTime? startTime,
    DateTime? endTime,
    Party? party,
    int currentParticipants = 8,
    int maxParticipants = 20,
  }) {
    return TodayActiveEvent(
      event: Event(
        id: id,
        partyId: 'party_1',
        title: title,
        startTime: startTime ??
            now.subtract(const Duration(minutes: 10)),
        endTime: endTime ?? now.add(const Duration(hours: 3)),
        createdAt: now,
        updatedAt: now,
        status: status,
        party: party,
        currentParticipants: currentParticipants,
        maxParticipants: maxParticipants,
      ),
      participantStatus: participantStatus,
    );
  }

  /// Renders EventNowBottomSheet directly in the widget tree
  /// with the eventNowBarState overridden to the given state.
  Widget createTestWidget(
    TodayActiveEvent activeEvent,
    EventNowBarState state,
  ) {
    return ProviderScope(
      overrides: [
        matchingRepositoryProvider.overrideWith(
          (ref) => mockMatchingRepo,
        ),
        ticketWalletRepositoryProvider.overrideWithValue(
          mockWallet,
        ),
        // Override the state provider to skip async resolution
        eventNowBarStateProvider(activeEvent).overrideWith(
          () => _FixedStateNotifier(state),
        ),
      ],
      child: MaterialApp(
        theme: MinglitTheme.materialTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: EventNowBottomSheet(
              activeEvent: activeEvent,
            ),
          ),
        ),
      ),
    );
  }

  group('EventNowBottomSheet', () {
    testWidgets(
      'Phase 1: shows QR code when ticket token exists',
      (tester) async {
        when(() => mockWallet.listAllTicketIds()).thenAnswer(
          (_) async => ['ticket_1'],
        );
        when(() => mockWallet.getTicket('ticket_1')).thenAnswer(
          (_) async => testToken,
        );

        final event = makeActiveEvent(party: testParty);
        await tester.pumpWidget(
          createTestWidget(event, EventNowBarState.checkInReady),
        );
        // Pump to let async providers resolve
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(find.byType(TicketQRViewer), findsOneWidget);
        expect(find.text('강남 밍릿파티'), findsOneWidget);
      },
    );

    testWidgets(
      'Phase 1: shows location link for deeplink navigation',
      (tester) async {
        when(() => mockWallet.listAllTicketIds()).thenAnswer(
          (_) async => ['ticket_1'],
        );
        when(() => mockWallet.getTicket('ticket_1')).thenAnswer(
          (_) async => testToken,
        );

        final event = makeActiveEvent(party: testParty);
        await tester.pumpWidget(
          createTestWidget(event, EventNowBarState.checkInReady),
        );
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(find.text('강남 라운지'), findsOneWidget);
        expect(find.text('위치 안내 보기'), findsOneWidget);
        expect(
          find.byIcon(Icons.location_on_outlined),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Phase 1: shows error + retry when QR token not found',
      (tester) async {
        when(() => mockWallet.listAllTicketIds()).thenAnswer(
          (_) async => [],
        );

        final event = makeActiveEvent();
        await tester.pumpWidget(
          createTestWidget(event, EventNowBarState.checkInReady),
        );
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(
          find.text('QR 코드를 불러올 수 없습니다'),
          findsOneWidget,
        );
        expect(find.text('다시 시도'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      },
    );

    testWidgets(
      'Phase 2: shows check-in complete with participant count',
      (tester) async {
        final event = makeActiveEvent(
          participantStatus: 'checked_in',
          currentParticipants: 8,
          maxParticipants: 20,
        );
        await tester.pumpWidget(
          createTestWidget(event, EventNowBarState.checkedIn),
        );
        await tester.pumpAndSettle();

        expect(find.text('체크인 완료!'), findsOneWidget);
        expect(find.text('참석자 8 / 20명'), findsOneWidget);
        expect(
          find.text('곧 매칭이 시작될 거예요'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.check), findsOneWidget);
        expect(
          find.byIcon(Icons.people_outline),
          findsOneWidget,
        );
      },
    );
  });
}

/// Test-only notifier that returns a fixed state immediately.
class _FixedStateNotifier extends EventNowBarStateNotifier {
  _FixedStateNotifier(this._fixedState);

  final EventNowBarState _fixedState;

  @override
  FutureOr<EventNowBarState> build(TodayActiveEvent activeEvent) {
    return _fixedState;
  }
}
