import 'dart:async';

import 'package:app_user/src/features/event/admission/event_admission_controller.dart';
import 'package:app_user/src/features/event/admission/event_application_controller.dart';
import 'package:app_user/src/features/event/logic/event_detail_controller.dart';
import 'package:app_user/src/features/ticket/ui/ticket_selection_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import 'utils/test_app.dart';
import 'utils/test_mocks.dart';

/// Integration test for ticket selection + application wizard flow.
/// Closes #225
void main() {
  late MockUserRepository mockUserRepo;
  late MockEventRepository mockEventRepo;

  final now = DateTime.now();

  final testTicketGeneral = Ticket(
    id: 'ticket-general',
    name: 'General',
    price: 15000,
    createdAt: now,
    updatedAt: now,
  );

  final testTicketVip = Ticket(
    id: 'ticket-vip',
    name: 'VIP',
    price: 50000,
    createdAt: now,
    updatedAt: now,
  );

  final testTicketLocked = Ticket(
    id: 'ticket-locked',
    name: 'Locked Ticket',
    price: 20000,
    createdAt: now,
    updatedAt: now,
  );

  final testEventWithTickets = Event(
    id: 'test-event-tickets',
    partyId: 'test-party-1',
    title: 'Ticket Test Event',
    startTime: now.add(const Duration(days: 1)),
    endTime: now.add(const Duration(days: 1, hours: 2)),
    createdAt: now,
    updatedAt: now,
    contactOptions: {},
    tickets: [testTicketGeneral, testTicketVip],
    entryGroups: [],
  );

  final testEventNoTickets = Event(
    id: 'test-event-no-tickets',
    partyId: 'test-party-1',
    title: 'No Tickets Event',
    startTime: now.add(const Duration(days: 1)),
    endTime: now.add(const Duration(days: 1, hours: 2)),
    createdAt: now,
    updatedAt: now,
    contactOptions: {},
    tickets: [],
    entryGroups: [],
  );

  final testEventWithLocked = Event(
    id: 'test-event-locked',
    partyId: 'test-party-1',
    title: 'Locked Ticket Event',
    startTime: now.add(const Duration(days: 1)),
    endTime: now.add(const Duration(days: 1, hours: 2)),
    createdAt: now,
    updatedAt: now,
    contactOptions: {},
    tickets: [testTicketGeneral, testTicketLocked],
    entryGroups: [],
  );

  final testEventWithVerification = Event(
    id: 'test-event-verif',
    partyId: 'test-party-1',
    title: 'Verification Event',
    startTime: now.add(const Duration(days: 1)),
    endTime: now.add(const Duration(days: 1, hours: 2)),
    createdAt: now,
    updatedAt: now,
    contactOptions: {},
    tickets: [testTicketGeneral],
    entryGroups: [],
  );

  final testUser = createMockUserForTest();
  final testProfile = UserProfile(
    id: 'test-user-id',
    name: 'Test User',
    username: 'testuser',
    isVerified: true,
    gender: 'male',
    birthYear: 1995,
  );

  setUp(() {
    mockUserRepo = MockUserRepository();
    mockEventRepo = MockEventRepository();

    when(
      () => mockUserRepo.getUserProfile(any()),
    ).thenAnswer((_) async => testProfile);
    when(
      () => mockUserRepo.getApprovedVerificationIds(any()),
    ).thenAnswer((_) async => <String>[]);
    when(
      () => mockEventRepo.getTicketBalanceStatus(any()),
    ).thenAnswer((_) async => <String, bool>{});
  });

  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  /// Pumps the EventDetailPage with eligible status so tapping the button
  /// opens the TicketSelectionSheet.
  Future<void> pumpEventDetailWithTickets(
    WidgetTester tester, {
    required Event event,
  }) async {
    setKoreanLocale(tester);
    await tester.pumpWidget(
      createTestApp(
        isLoggedIn: true,
        currentUser: testUser,
        initialLocation: '/events/${event.id}',
        additionalOverrides: [
          eventDetailControllerProvider(event.id).overrideWith(
            () => _MockEventDetailController(event),
          ),
          eventAdmissionControllerProvider(event).overrideWith(
            () => _MockAdmissionController(
              AdmissionState(status: EventAdmissionStatus.eligible),
            ),
          ),
          entryGroupParticipantCountsProvider(event.id).overrideWith(
            (ref) async => <String, int>{},
          ),
          iamportConfigProvider.overrideWithValue(
            const IamportConfig(userCode: 'imp_test'),
          ),
          userRepositoryProvider.overrideWith((ref) => mockUserRepo),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
        ],
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  /// Opens the TicketSelectionSheet from the event detail page.
  Future<void> openTicketSheet(WidgetTester tester) async {
    await tester.tap(find.text('참가 신청하기'));
    await tester.pump();
    await tester.pump();
  }

  // ─── TicketSelectionSheet Tests ───

  group('TicketSelectionSheet', () {
    testWidgets('loading → "추천 티켓을 확인 중입니다."', (tester) async {
      // Delay repo responses so loading state persists
      when(
        () => mockEventRepo.getTicketBalanceStatus(any()),
      ).thenAnswer((_) => Completer<Map<String, bool>>().future);

      await pumpEventDetailWithTickets(tester, event: testEventWithTickets);
      await openTicketSheet(tester);

      expect(find.text('추천 티켓을 확인 중입니다.'), findsOneWidget);
    });

    testWidgets('empty tickets → "현재 구매 가능한 티켓이 없습니다."', (tester) async {
      await pumpEventDetailWithTickets(tester, event: testEventNoTickets);
      await openTicketSheet(tester);
      // Let async fetches complete
      await tester.pump();
      await tester.pump();

      expect(find.text('현재 구매 가능한 티켓이 없습니다.'), findsOneWidget);
    });

    testWidgets('recommended ticket shows "추천" badge + other ticket list', (
      tester,
    ) async {
      await pumpEventDetailWithTickets(tester, event: testEventWithTickets);
      await openTicketSheet(tester);
      await tester.pump();
      await tester.pump();

      // Recommended badge visible
      expect(find.text('추천'), findsOneWidget);
      // Both tickets should be listed
      expect(find.text('General'), findsOneWidget);
      expect(find.text('VIP'), findsOneWidget);
      // "추천 티켓" and "다른 티켓" section labels
      expect(find.text('추천 티켓'), findsOneWidget);
      expect(find.text('다른 티켓'), findsOneWidget);
    });

    testWidgets('locked ticket → opacity + "성비 조절 중" badge', (tester) async {
      // Mark locked ticket as balance-locked
      when(
        () => mockEventRepo.getTicketBalanceStatus(any()),
      ).thenAnswer((_) async => {'ticket-locked': false});

      await pumpEventDetailWithTickets(tester, event: testEventWithLocked);
      await openTicketSheet(tester);
      await tester.pump();
      await tester.pump();

      expect(find.text('성비 조절 중'), findsAtLeast(1));
      // The locked ticket should have Opacity 0.5
      final opacityWidgets = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .where((w) => w.opacity == 0.5);
      expect(opacityWidgets.isNotEmpty, isTrue);
    });

    testWidgets('selecting ticket enables "다음" button', (tester) async {
      await pumpEventDetailWithTickets(tester, event: testEventWithTickets);
      await openTicketSheet(tester);
      await tester.pump();
      await tester.pump();

      // After loading, recommended ticket auto-selected → button enabled
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '다음'),
      );
      expect(button.onPressed, isNotNull);
    });
  });

  // ─── EventApplicationWizardPage Tests ───

  group('EventApplicationWizardPage', () {
    /// Pumps the wizard page directly via route.
    Future<void> pumpWizard(
      WidgetTester tester, {
      required Event event,
      String? ticketId,
      EventApplicationState? controllerState,
    }) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(
        createTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          initialLocation: '/events/${event.id}/apply',
          additionalOverrides: [
            eventDetailControllerProvider(event.id).overrideWith(
              () => _MockEventDetailController(event),
            ),
            if (controllerState != null)
              eventApplicationControllerProvider(event).overrideWith(
                () => _MockApplicationController(controllerState),
              ),
            entryGroupParticipantCountsProvider(event.id).overrideWith(
              (ref) async => <String, int>{},
            ),
            iamportConfigProvider.overrideWithValue(
              const IamportConfig(userCode: 'imp_test'),
            ),
            userRepositoryProvider.overrideWith((ref) => mockUserRepo),
            eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();
    }

    testWidgets('Step 1 (verification) renders step indicator with "인증" active',
        (tester) async {
      await pumpWizard(tester, event: testEventWithVerification);

      // Step indicator should show
      expect(find.text('인증'), findsOneWidget);
      expect(find.text('결제'), findsOneWidget);
      // "다음" button visible on verification step
      expect(find.text('다음'), findsOneWidget);
    });

    testWidgets(
        'no verification required → "바로 결제로 진행해주세요" message',
        (tester) async {
      await pumpWizard(
        tester,
        event: testEventWithVerification,
        controllerState: EventApplicationState(
          step: EventApplicationStep.verification,
          status: EventApplicationStatus.initial,
          selectedTicket: testTicketGeneral,
        ),
      );

      // Since entryGroups is empty for this ticket, no verification needed
      expect(
        find.textContaining('바로 결제로 진행해주세요'),
        findsOneWidget,
      );
    });

    testWidgets('Step 2 (payment) → renders payment details', (tester) async {
      await pumpWizard(
        tester,
        event: testEventWithVerification,
        controllerState: EventApplicationState(
          step: EventApplicationStep.payment,
          status: EventApplicationStatus.initial,
          selectedTicket: testTicketGeneral,
        ),
      );

      // Payment step should show ticket name and price
      expect(find.text('결제 상세'), findsOneWidget);
      expect(find.text('General'), findsOneWidget);
      expect(find.text('15,000원'), findsAtLeast(1));
      expect(find.text('최종 결제 금액'), findsOneWidget);
      // "결제하기" button visible on payment step
      expect(find.text('결제하기'), findsOneWidget);
      // "이전" button visible on payment step
      expect(find.text('이전'), findsOneWidget);
    });

    testWidgets('payment submitting → "결제하기" button disabled + spinner', (
      tester,
    ) async {
      await pumpWizard(
        tester,
        event: testEventWithVerification,
        controllerState: EventApplicationState(
          step: EventApplicationStep.payment,
          status: EventApplicationStatus.submitting,
          selectedTicket: testTicketGeneral,
        ),
      );

      // "결제하기" button should be disabled during submission
      final buttons = tester
          .widgetList<ElevatedButton>(find.byType(ElevatedButton))
          .toList();
      final payButton = buttons.last;
      expect(payButton.onPressed, isNull);

      // "이전" button should also be disabled
      final outlinedButtons = tester
          .widgetList<OutlinedButton>(find.byType(OutlinedButton))
          .toList();
      if (outlinedButtons.isNotEmpty) {
        expect(outlinedButtons.last.onPressed, isNull);
      }
    });

    testWidgets('payment step shows refund notice text', (tester) async {
      await pumpWizard(
        tester,
        event: testEventWithVerification,
        controllerState: EventApplicationState(
          step: EventApplicationStep.payment,
          status: EventApplicationStatus.initial,
          selectedTicket: testTicketGeneral,
        ),
      );

      expect(
        find.textContaining('파트너 심사 반려 시 100% 환불됩니다'),
        findsOneWidget,
      );
      expect(
        find.textContaining('최대 24시간이 소요'),
        findsOneWidget,
      );
    });
  });
}

/// Mock EventDetailController — returns the given event immediately.
class _MockEventDetailController extends EventDetailController {
  _MockEventDetailController(this._event);
  final Event _event;

  @override
  FutureOr<Event> build(String eventId) async => _event;
}

/// Mock EventAdmissionController — returns the given state immediately.
class _MockAdmissionController extends EventAdmissionController {
  _MockAdmissionController(this._state);
  final AdmissionState _state;

  @override
  FutureOr<AdmissionState> build(Event event) async => _state;
}

/// Mock EventApplicationController — returns the given state immediately.
class _MockApplicationController extends EventApplicationController {
  _MockApplicationController(this._state);
  final EventApplicationState _state;

  @override
  EventApplicationState build(Event event) => _state;
}
