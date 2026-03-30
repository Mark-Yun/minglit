import 'dart:async';

import 'package:app_user/src/features/auth/login_page.dart';
import 'package:app_user/src/features/event/admission/event_admission_controller.dart';
import 'package:app_user/src/features/event/logic/event_detail_controller.dart';
import 'package:app_user/src/features/ticket/ui/ticket_selection_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import 'utils/test_app.dart';
import 'utils/test_mocks.dart';

/// Integration test for EventAdmissionStatus 8-state button rendering & tap actions.
/// Closes #224
void main() {
  late MockUserRepository mockUserRepo;
  late MockEventRepository mockEventRepo;

  setUp(() {
    mockUserRepo = MockUserRepository();
    mockEventRepo = MockEventRepository();

    // Stub methods called by TicketSelectionSheet
    when(
      () => mockEventRepo.getTicketBalanceStatus(any()),
    ).thenAnswer((_) async => <String, bool>{});
    when(
      () => mockUserRepo.getUserProfile(any()),
    ).thenAnswer((_) async => null);
    when(
      () => mockUserRepo.getApprovedVerificationIds(any()),
    ).thenAnswer((_) async => <String>[]);
    // Fix #299: cancelOrder EF stub for rejected → re-apply flow
    when(
      () => mockEventRepo.cancelOrder(
        eventId: any(named: 'eventId'),
        reason: any(named: 'reason'),
      ),
    ).thenAnswer(
      (_) async => const CancelOrderResult(type: 'cancelled'),
    );
  });

  final testEvent = Event(
    id: 'test-event-admission',
    partyId: 'test-party-1',
    title: 'Admission Test Event',
    startTime: DateTime.now().add(const Duration(days: 1)),
    endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    contactOptions: {},
    tickets: [
      Ticket(
        id: 'test-ticket-1',
        name: 'General',
        price: 15000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ],
    entryGroups: [],
  );

  final testUser = createMockUserForTest();

  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  /// Pumps the EventDetailPage with the given [admissionState] injected.
  Future<void> pumpEventDetailWithState(
    WidgetTester tester, {
    required AdmissionState admissionState,
    bool isLoggedIn = true,
    User? currentUser,
  }) async {
    setKoreanLocale(tester);
    await tester.pumpWidget(
      createTestApp(
        isLoggedIn: isLoggedIn,
        currentUser: currentUser,
        initialLocation: '/events/${testEvent.id}',
        additionalOverrides: [
          eventDetailControllerProvider(testEvent.id).overrideWith(
            () => _MockEventDetailController(testEvent),
          ),
          eventAdmissionControllerProvider(testEvent).overrideWith(
            () => _MockAdmissionController(admissionState),
          ),
          // Prevent partner detail API calls from event detail content
          entryGroupParticipantCountsProvider(testEvent.id).overrideWith(
            (ref) async => <String, int>{},
          ),
          // Provide test IamportConfig to avoid platform channel errors
          iamportConfigProvider.overrideWithValue(
            const IamportConfig(userCode: 'imp_test'),
          ),
          // Mock repositories to avoid Supabase initialization errors
          // (needed when TicketSelectionSheet or handleAction accesses repos)
          userRepositoryProvider.overrideWith((ref) => mockUserRepo),
          eventRepositoryProvider.overrideWith((ref) => mockEventRepo),
        ],
      ),
    );
    // Pump multiple frames to let async providers resolve
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  group('AdmissionStatus 버튼 렌더링 (8가지 상태)', () {
    testWidgets('guest → "로그인하고 신청하기" (enabled)', (tester) async {
      await pumpEventDetailWithState(
        tester,
        admissionState: AdmissionState(status: EventAdmissionStatus.guest),
        isLoggedIn: false,
      );

      expect(find.text('로그인하고 신청하기'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '로그인하고 신청하기'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('identityRequired → "본인인증 후 신청하기" (enabled)', (
      tester,
    ) async {
      await pumpEventDetailWithState(
        tester,
        admissionState: AdmissionState(
          status: EventAdmissionStatus.identityRequired,
        ),
        currentUser: testUser,
      );

      expect(find.text('본인인증 후 신청하기'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '본인인증 후 신청하기'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('qualificationRequired → "신청하기" (enabled)', (tester) async {
      await pumpEventDetailWithState(
        tester,
        admissionState: AdmissionState(
          status: EventAdmissionStatus.qualificationRequired,
          missingVerificationIds: ['verif_1'],
        ),
        currentUser: testUser,
      );

      expect(find.text('신청하기'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '신청하기'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('notEligible → 사유 텍스트 (disabled)', (tester) async {
      await pumpEventDetailWithState(
        tester,
        admissionState: AdmissionState(
          status: EventAdmissionStatus.notEligible,
          ineligibleReason: '나이 조건이 맞지 않습니다.',
        ),
        currentUser: testUser,
      );

      expect(find.text('나이 조건이 맞지 않습니다.'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '나이 조건이 맞지 않습니다.'),
      );
      expect(button.onPressed, isNull);
      // Disabled style: backgroundColor = theme.colorScheme.outline
      final theme = Theme.of(tester.element(find.byType(ElevatedButton).last));
      final bg = button.style?.backgroundColor?.resolve({});
      expect(bg, theme.colorScheme.outline);
    });

    testWidgets('eligible → "참가 신청하기" (enabled)', (tester) async {
      await pumpEventDetailWithState(
        tester,
        admissionState: AdmissionState(
          status: EventAdmissionStatus.eligible,
        ),
        currentUser: testUser,
      );

      expect(find.text('참가 신청하기'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '참가 신청하기'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('pendingPayment → "결제 계속하기" (enabled)', (tester) async {
      await pumpEventDetailWithState(
        tester,
        admissionState: AdmissionState(
          status: EventAdmissionStatus.pendingPayment,
        ),
        currentUser: testUser,
      );

      expect(find.text('결제 계속하기'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '결제 계속하기'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('applied → "이미 신청한 이벤트" (enabled)', (tester) async {
      await pumpEventDetailWithState(
        tester,
        admissionState: AdmissionState(
          status: EventAdmissionStatus.applied,
        ),
        currentUser: testUser,
      );

      expect(find.text('이미 신청한 이벤트'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '이미 신청한 이벤트'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('rejected → "심사 반려 (사유 확인)" (destructive)', (
      tester,
    ) async {
      await pumpEventDetailWithState(
        tester,
        admissionState: AdmissionState(
          status: EventAdmissionStatus.rejected,
          rejectionReason: '서류 부족',
        ),
        currentUser: testUser,
      );

      expect(find.text('심사 반려 (사유 확인)'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '심사 반려 (사유 확인)'),
      );
      expect(button.onPressed, isNotNull);
      // Destructive style: backgroundColor = theme.colorScheme.error
      final theme = Theme.of(tester.element(find.byType(ElevatedButton).last));
      final bg = button.style?.backgroundColor?.resolve({});
      expect(bg, theme.colorScheme.error);
    });

    testWidgets('eligible → normal style (no custom backgroundColor)', (
      tester,
    ) async {
      await pumpEventDetailWithState(
        tester,
        admissionState: AdmissionState(
          status: EventAdmissionStatus.eligible,
        ),
        currentUser: testUser,
      );

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '참가 신청하기'),
      );
      // Normal style: no custom backgroundColor override
      expect(button.style?.backgroundColor, isNull);
    });
  });

  group('AdmissionStatus 버튼 탭 동작', () {
    testWidgets('guest 탭 → LoginPage로 이동', (tester) async {
      await pumpEventDetailWithState(
        tester,
        admissionState: AdmissionState(status: EventAdmissionStatus.guest),
        isLoggedIn: false,
      );

      await tester.tap(find.text('로그인하고 신청하기'));
      // Use pump() instead of pumpAndSettle() — LoginPage has ongoing animations
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('identityRequired 탭 → IdentityVerificationScreen 모달', (
      tester,
    ) async {
      await pumpEventDetailWithState(
        tester,
        admissionState: AdmissionState(
          status: EventAdmissionStatus.identityRequired,
        ),
        currentUser: testUser,
      );

      await tester.tap(find.text('본인인증 후 신청하기'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(IdentityVerificationScreen), findsOneWidget);
    });

    testWidgets('eligible 탭 → TicketSelectionSheet 바텀시트', (tester) async {
      await pumpEventDetailWithState(
        tester,
        admissionState: AdmissionState(
          status: EventAdmissionStatus.eligible,
        ),
        currentUser: testUser,
      );

      await tester.tap(find.text('참가 신청하기'));
      await tester.pump();
      await tester.pump();

      expect(find.byType(TicketSelectionSheet), findsOneWidget);
    });

    testWidgets('rejected 탭 → 재신청 확인 다이얼로그', (tester) async {
      await pumpEventDetailWithState(
        tester,
        admissionState: AdmissionState(
          status: EventAdmissionStatus.rejected,
          rejectionReason: '서류 부족',
          user: testUser,
        ),
        currentUser: testUser,
      );

      await tester.tap(find.text('심사 반려 (사유 확인)'));
      await tester.pump();
      await tester.pump();

      // Verify the confirmation dialog shows rejection reason
      expect(find.text('심사 결과 안내'), findsOneWidget);
      expect(find.textContaining('서류 부족'), findsOneWidget);
      expect(find.text('다시 신청하기'), findsOneWidget);
      expect(find.text('닫기'), findsOneWidget);
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
