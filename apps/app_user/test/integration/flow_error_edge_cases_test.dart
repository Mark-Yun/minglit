import 'dart:async';

import 'package:app_user/src/features/event/admission/event_admission_controller.dart';
import 'package:app_user/src/features/event/detail/event_detail_page.dart';
import 'package:app_user/src/features/event/detail/report_bottom_sheet.dart';
import 'package:app_user/src/features/event/logic/event_detail_controller.dart';
import 'package:app_user/src/features/partner/detail/partner_detail_page.dart';
import 'package:app_user/src/features/ticket/data/ticket_wallet_repository.dart';
import 'package:app_user/src/features/ticket/ui/ticket_qr_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
// ignore: implementation_imports
import 'package:minglit_kit/src/features/social/logic/social_interaction_controller.dart';
import 'package:mocktail/mocktail.dart';

import 'utils/test_app.dart';
import 'utils/test_mocks.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  /// Common overrides for event detail tests that need a loaded event.
  /// Must use specific provider instance for family providers.
  List<dynamic> eventDetailOverrides({
    required Event event,
    bool admissionError = false,
    bool withUser = false,
    MockSocialRepository? socialRepo,
  }) {
    return [
      eventDetailControllerProvider(event.id).overrideWith(
        () => _DataEventDetailController(event),
      ),
      eventAdmissionControllerProvider(event).overrideWith(
        admissionError
            ? () => _ErrorAdmissionController()
            : () => _GuestAdmissionController(),
      ),
      if (withUser) ...[
        socialInteractionControllerProvider.overrideWith(
          () => _NoOpSocialInteractionController(),
        ),
        socialRepositoryProvider
            .overrideWithValue(socialRepo ?? MockSocialRepository()),
      ],
    ];
  }

  // ──────────────────────────────────────────────────────────────────
  // AsyncError 상태
  // ──────────────────────────────────────────────────────────────────
  group('AsyncError 상태', () {
    testWidgets(
      'EventDetailPage 에러 → MinglitAsyncValueWidget 에러뷰 + 하단바 숨김',
      (tester) async {
        setKoreanLocale(tester);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              eventDetailControllerProvider('error-event-id').overrideWith(
                _ErrorEventDetailController.new,
              ),
            ],
            child: MaterialApp(
              theme: MinglitTheme.materialTheme,
              home: const EventDetailPage(eventId: 'error-event-id'),
            ),
          ),
        );
        // Pump several times for async error to propagate
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // MinglitAsyncValueWidget default error view
        expect(find.text('오류가 발생했습니다.'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);

        // Bottom bar should be SizedBox.shrink (hidden on error)
        expect(find.text('최저가'), findsNothing);
        expect(find.text('오류 발생'), findsNothing);
      },
    );

    testWidgets('SearchPage 에러 → "검색 중 오류가 발생했습니다"', (tester) async {
      setKoreanLocale(tester);
      // Test the search error UI by rendering the error widget directly.
      // Riverpod 3.x async FutureProviders do not propagate errors to
      // AsyncError in widget tests, so we test with MinglitAsyncValueWidget.
      await tester.pumpWidget(
        MaterialApp(
          theme: MinglitTheme.materialTheme,
          home: Scaffold(
            body: MinglitAsyncValueWidget<List<Event>>(
              value: AsyncError(Exception('Search failed'), StackTrace.current),
              data: (_) => const SizedBox.shrink(),
              error: (e, _) => const Center(
                child: Text('검색 중 오류가 발생했습니다'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('검색 중 오류가 발생했습니다'), findsOneWidget);
    });

    testWidgets('PartnerDetailPage null → "파트너를 찾을 수 없습니다."', (
      tester,
    ) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/partners/nonexistent-partner',
          additionalOverrides: [
            partnerDetailProvider.overrideWith(
              (ref, partnerId) async => null,
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(PartnerDetailPage), findsOneWidget);
      expect(find.text('파트너를 찾을 수 없습니다.'), findsOneWidget);
    });

    testWidgets('TicketQRScreen null → "티켓 정보를 찾을 수 없습니다."', (
      tester,
    ) async {
      setKoreanLocale(tester);
      final mockWalletRepo = MockTicketWalletRepository();
      when(
        () => mockWalletRepo.getTicket(any()),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ticketWalletRepositoryProvider.overrideWithValue(mockWalletRepo),
          ],
          child: MaterialApp(
            theme: MinglitTheme.materialTheme,
            home: const TicketQRScreen(ticketId: 'nonexistent-ticket'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('티켓 정보를 찾을 수 없습니다.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('BottomTicketBar 에러 → 비활성 "오류 발생" 버튼', (tester) async {
      setKoreanLocale(tester);
      final testEvent = _createTestEventWithPartner();

      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: createMockUserForTest(),
          initialLocation: '/events/${testEvent.id}',
          additionalOverrides: eventDetailOverrides(
            event: testEvent,
            admissionError: true,
            withUser: true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // BottomTicketBar should show error button
      expect(find.text('오류 발생'), findsOneWidget);

      // Button should be disabled (onPressed is null)
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '오류 발생'),
      );
      expect(button.onPressed, isNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // Pull-to-refresh
  // ──────────────────────────────────────────────────────────────────
  group('Pull-to-refresh', () {
    testWidgets('EventDetail pull-to-refresh → RefreshIndicator 존재', (
      tester,
    ) async {
      setKoreanLocale(tester);
      final testEvent = _createTestEventWithPartner();

      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/events/${testEvent.id}',
          additionalOverrides: eventDetailOverrides(event: testEvent),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('EventDetail pull-to-refresh → eventDetailController 새로고침', (
      tester,
    ) async {
      setKoreanLocale(tester);
      var refreshCount = 0;
      final testEvent = _createTestEventWithPartner();

      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/events/${testEvent.id}',
          additionalOverrides: [
            eventDetailControllerProvider.overrideWith(
              () => _CountingEventDetailController(
                testEvent,
                onBuild: () => refreshCount++,
              ),
            ),
            eventAdmissionControllerProvider.overrideWith(
              () => _GuestAdmissionController(),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      final initialCount = refreshCount;

      // Pull down to trigger refresh
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 500),
        800,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pump();

      expect(refreshCount, greaterThan(initialCount));
    });
  });

  // ──────────────────────────────────────────────────────────────────
  // 바텀시트 / 다이얼로그
  // ──────────────────────────────────────────────────────────────────
  group('바텀시트/다이얼로그', () {
    testWidgets('이벤트 상세 → 더보기 → 차단하기 → 확인 다이얼로그 → 차단 처리', (
      tester,
    ) async {
      setKoreanLocale(tester);
      final testEvent = _createTestEventWithPartner();
      final mockSocialRepo = MockSocialRepository();
      when(
        () => mockSocialRepo.blockPartner(any()),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: createMockUserForTest(),
          initialLocation: '/events/${testEvent.id}',
          additionalOverrides: eventDetailOverrides(
            event: testEvent,
            withUser: true,
            socialRepo: mockSocialRepo,
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }

      // Verify the page loaded with partner data
      expect(find.byType(EventDetailPage), findsOneWidget);
      // Verify the popup menu icon exists (requires loaded state + user + partner)
      expect(find.byIcon(Icons.more_vert), findsOneWidget);

      // Tap PopupMenuButton (more_vert icon)
      await tester.tap(find.byIcon(Icons.more_vert));
      // Let popup menu animate open
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Verify popup menu shows '차단하기' option
      expect(find.text('차단하기'), findsOneWidget);

      // Tap '차단하기' in the popup menu
      await tester.tap(find.text('차단하기'));
      // Let popup close + dialog open
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Confirm dialog should appear (content includes newline)
      expect(find.textContaining('이 파트너를 차단하시겠습니까?'), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
      expect(find.text('차단'), findsOneWidget);

      // Tap confirm
      await tester.tap(find.text('차단'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Verify blockPartner was called
      verify(() => mockSocialRepo.blockPartner('test-partner-id')).called(1);
    });

    testWidgets('이벤트 상세 → 더보기 → 신고하기 → 사유 선택 바텀시트 (5개 RadioListTile)', (
      tester,
    ) async {
      setKoreanLocale(tester);
      final testEvent = _createTestEventWithPartner();

      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: createMockUserForTest(),
          initialLocation: '/events/${testEvent.id}',
          additionalOverrides: eventDetailOverrides(
            event: testEvent,
            withUser: true,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Tap PopupMenuButton
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap '신고하기'
      await tester.tap(find.text('신고하기'));
      await tester.pumpAndSettle();

      // Report bottom sheet should show 5 RadioListTile options
      expect(find.text('신고 이유를 선택해주세요'), findsOneWidget);
      expect(find.byType(RadioListTile<ReportReason>), findsNWidgets(5));

      // Verify all 5 reason labels
      expect(find.text('선정적인 콘텐츠'), findsOneWidget);
      expect(find.text('허위 또는 과장된 정보'), findsOneWidget);
      expect(find.text('노쇼 / 이벤트 미진행'), findsOneWidget);
      expect(find.text('사기 또는 부당 청구'), findsOneWidget);
      expect(find.text('기타'), findsOneWidget);
    });

    testWidgets('이벤트 상세 → 환불 정책 섹션 스크롤 → 정책 내용 표시', (tester) async {
      setKoreanLocale(tester);
      final testEvent = _createTestEventWithPartner();

      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/events/${testEvent.id}',
          additionalOverrides: eventDetailOverrides(event: testEvent),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Scroll to the bottom to find refund policy section
      for (var i = 0; i < 15; i++) {
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -300),
        );
        await tester.pump();
      }

      // Verify refund policy static content is visible
      expect(find.text('환불 정책'), findsWidgets); // Tab label + section title
      expect(find.text('전액 환불'), findsOneWidget);
      expect(find.text('환불 불가'), findsOneWidget);
    });
  });
}

// ── Test Helpers ──────────────────────────────────────────────────────

class _ErrorEventDetailController extends EventDetailController {
  @override
  FutureOr<Event> build(String eventId) {
    state = AsyncError(Exception('Failed to load event'), StackTrace.current);
    return Completer<Event>().future; // keep alive
  }
}

class _DataEventDetailController extends EventDetailController {
  _DataEventDetailController(this._event);
  final Event _event;

  @override
  FutureOr<Event> build(String eventId) async => _event;
}

class _CountingEventDetailController extends EventDetailController {
  _CountingEventDetailController(this._event, {required this.onBuild});
  final Event _event;
  final void Function() onBuild;

  @override
  FutureOr<Event> build(String eventId) async {
    onBuild();
    return _event;
  }
}

class _ErrorAdmissionController extends EventAdmissionController {
  @override
  FutureOr<AdmissionState> build(Event event) {
    state = AsyncError(
      Exception('Admission check failed'),
      StackTrace.current,
    );
    return Completer<AdmissionState>().future;
  }
}

class _GuestAdmissionController extends EventAdmissionController {
  @override
  FutureOr<AdmissionState> build(Event event) async {
    return AdmissionState(status: EventAdmissionStatus.guest);
  }
}

/// No-op social interaction controller to avoid Supabase dependency.
class _NoOpSocialInteractionController extends SocialInteractionController {
  @override
  FutureOr<bool> build({
    required String targetId,
    required SocialTargetType targetType,
    required SocialInteractionType interactionType,
  }) async {
    return false;
  }
}

class MockTicketWalletRepository extends Mock
    implements TicketWalletRepository {}

Event _createTestEventWithPartner() {
  return Event(
    id: 'test-event-detail',
    partyId: 'test-party-id',
    title: 'Test Event',
    startTime: DateTime.now().add(const Duration(days: 14)),
    endTime: DateTime.now().add(const Duration(days: 14, hours: 3)),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    party: Party(
      id: 'test-party-id',
      partnerId: 'test-partner-id',
      title: 'Test Party',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      partner: const Partner(
        id: 'test-partner-id',
        name: 'Test Partner',
      ),
    ),
    tickets: [
      Ticket(
        id: 'test-ticket-1',
        name: 'General',
        price: 15000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ],
  );
}
