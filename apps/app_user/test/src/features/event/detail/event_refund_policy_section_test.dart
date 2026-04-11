import 'dart:async';

import 'package:app_user/src/features/event/admission/event_admission_controller.dart';
import 'package:app_user/src/features/event/detail/event_detail_now_provider.dart';
import 'package:app_user/src/features/event/logic/event_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../../../../integration/utils/test_app.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  /// Creates provider overrides for EventDetailPage with refund policy control.
  List<dynamic> refundPolicyOverrides({
    required Event event,
    required DateTime now,
    int gracePeriodHours = 2,
    int cutoffDays = 7,
    bool nullPolicy = false,
  }) {
    return [
      eventDetailControllerProvider(
        event.id,
      ).overrideWith(() => _DataEventDetailController(event)),
      eventAdmissionControllerProvider(
        event,
      ).overrideWith(_GuestAdmissionController.new),
      policyRepositoryProvider.overrideWith(
        (ref) => _FakePolicyRepository(
          gracePeriodHours: gracePeriodHours,
          cutoffDays: cutoffDays,
          returnNull: nullPolicy,
        ),
      ),
      eventDetailNowProvider.overrideWith(
        (_) =>
            () => now,
      ),
    ];
  }

  /// Pumps EventDetailPage and scrolls to refund policy section.
  Future<void> pumpAndScrollToRefundPolicy(
    WidgetTester tester,
    Event event, {
    List<dynamic> overrides = const [],
  }) async {
    setKoreanLocale(tester);
    await tester.pumpWidget(
      createTestApp(
        initialLocation: '/events/${event.id}',
        additionalOverrides: overrides,
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    // Scroll down to refund policy section
    await tester.dragUntilVisible(
      find.text('환불 정책'),
      find.byType(CustomScrollView),
      const Offset(0, -300),
    );
    await tester.pump();
  }

  group('_RefundPolicySection', () {
    // ──────────────────────────────────────────────────────────────────
    // cutoff 이전 → primary 배너 + "~까지 환불 가능" + D-day 텍스트
    // ──────────────────────────────────────────────────────────────────
    testWidgets('cutoff 이전 → 환불 가능 배너 + D-day 표시', (tester) async {
      final now = DateTime(2026, 4, 1, 10);
      final event = _createTestEvent(
        startTime: now.add(const Duration(days: 14)),
        referenceTime: now,
      );
      final overrides = refundPolicyOverrides(event: event, now: now);

      await pumpAndScrollToRefundPolicy(tester, event, overrides: overrides);

      // "~까지 환불 가능" 텍스트가 포함된 배너
      expect(find.textContaining('까지 환불 가능'), findsOneWidget);
      // D-day 텍스트 (일 후) — cutoff = startTime - 7 = 7 days from now
      expect(find.textContaining('일 후'), findsOneWidget);
      // check_circle_outline 아이콘 (primary 배너)
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      // 보조 텍스트: grace period 안내
      expect(find.text('결제 후 2시간 이내에도 전액 환불 가능'), findsOneWidget);
    });

    // ──────────────────────────────────────────────────────────────────
    // cutoff 경과 → secondary 배너 + grace period 안내
    // ──────────────────────────────────────────────────────────────────
    testWidgets('cutoff 경과 → grace period 환불 안내 배너', (tester) async {
      final now = DateTime(2026, 4, 1, 10);
      // startTime 3일 후 → cutoff = 3 - 7 = 4일 전 (이미 경과)
      final event = _createTestEvent(
        startTime: now.add(const Duration(days: 3)),
        referenceTime: now,
      );
      final overrides = refundPolicyOverrides(event: event, now: now);

      await pumpAndScrollToRefundPolicy(tester, event, overrides: overrides);

      // grace period 배너
      expect(find.text('결제 후 2시간 이내 전액 환불 가능'), findsOneWidget);
      // schedule 아이콘 (secondary 배너)
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      // 보조 텍스트: cutoff 마감 안내
      expect(find.text('이벤트 시작 7일 전 환불 마감'), findsOneWidget);
      // cutoff 이전 배너는 없어야 함
      expect(find.textContaining('까지 환불 가능'), findsNothing);
    });

    // ──────────────────────────────────────────────────────────────────
    // Fix #138: cutoff 당일(경계값) → isCutoffRefundable = true
    // ──────────────────────────────────────────────────────────────────
    testWidgets('cutoff 당일 경계값 → 환불 가능 (isCutoffRefundable=true)', (
      tester,
    ) async {
      // Fix #138: cutoff 경계값 포함 검증
      // Set cutoffDate to end of today (23:59) so:
      //   isCutoffRefundable = !now.isAfter(cutoffDate) = true
      //   daysLeft = 0 (same calendar day) → shows "(오늘)"
      final now = DateTime(2026, 4, 1, 10);
      final endOfToday = DateTime(
        now.year,
        now.month,
        now.day + 1,
      ).subtract(const Duration(microseconds: 1));
      final event = _createTestEvent(
        startTime: endOfToday.add(const Duration(days: 7)),
        referenceTime: now,
      );
      final overrides = refundPolicyOverrides(event: event, now: now);

      await pumpAndScrollToRefundPolicy(tester, event, overrides: overrides);

      // cutoff 당일에는 "오늘" 표시와 함께 환불 가능 배너
      expect(find.textContaining('까지 환불 가능'), findsOneWidget);
      expect(find.textContaining('오늘'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    // ──────────────────────────────────────────────────────────────────
    // policy null → 기본값 적용 (grace_period_hours=2, cutoff_days=7)
    // ──────────────────────────────────────────────────────────────────
    testWidgets('policy null → 기본값(grace=2h, cutoff=7d) 적용', (tester) async {
      final now = DateTime(2026, 4, 1, 10);
      final event = _createTestEvent(
        startTime: now.add(const Duration(days: 14)),
        referenceTime: now,
      );
      final overrides = refundPolicyOverrides(
        event: event,
        now: now,
        nullPolicy: true,
      );

      await pumpAndScrollToRefundPolicy(tester, event, overrides: overrides);

      // 기본값으로 렌더링됨 — 14일 후 시작이면 cutoff = 7일 후 (환불 가능)
      expect(find.textContaining('까지 환불 가능'), findsOneWidget);
      expect(find.text('결제 후 2시간 이내에도 전액 환불 가능'), findsOneWidget);
    });

    // ──────────────────────────────────────────────────────────────────
    // 인포 버튼 탭 → 바텀시트 표시 + 3단계 환불 정책 행 표시
    // ──────────────────────────────────────────────────────────────────
    testWidgets('인포 버튼 탭 → 환불 정책 상세 바텀시트 + 3행 표시', (tester) async {
      final now = DateTime(2026, 4, 1, 10);
      final event = _createTestEvent(
        startTime: now.add(const Duration(days: 14)),
        referenceTime: now,
      );
      final overrides = refundPolicyOverrides(event: event, now: now);

      await pumpAndScrollToRefundPolicy(tester, event, overrides: overrides);

      // 인포 버튼이 보이도록 ensure
      final infoButton = find.byTooltip('환불 정책 상세');
      await tester.ensureVisible(infoButton);
      await tester.pump();

      // 인포 버튼 탭
      await tester.tap(infoButton);
      await tester.pumpAndSettle();

      // 바텀시트 제목
      expect(find.text('환불 정책 상세'), findsOneWidget);
      // 3단계 환불 정책 행
      expect(find.text('결제 후 2시간 이내'), findsOneWidget);
      expect(find.text('이벤트 시작 7일 전까지'), findsOneWidget);
      expect(find.text('그 외'), findsOneWidget);
      // 환불 가능/불가 결과
      expect(find.text('전액 환불'), findsNWidgets(2));
      // Fix #1140: "환불 불가" → "고객센터 문의"로 변경됨
      expect(find.text('고객센터 문의'), findsOneWidget);
      // 고객센터 안내
      expect(find.text('자세한 내용은 고객센터로 문의해주세요.'), findsOneWidget);
    });
  });
}

// ── Test Helpers ──────────────────────────────────────────────────────

Event _createTestEvent({
  required DateTime startTime,
  required DateTime referenceTime,
}) {
  return Event(
    id: 'refund-test-event',
    partyId: 'test-party-id',
    title: 'Refund Policy Test Event',
    startTime: startTime,
    endTime: startTime.add(const Duration(hours: 3)),
    createdAt: referenceTime,
    updatedAt: referenceTime,
    party: Party(
      id: 'test-party-id',
      partnerId: 'test-partner-id',
      title: 'Test Party',
      createdAt: referenceTime,
      updatedAt: referenceTime,
      partner: const Partner(id: 'test-partner-id', name: 'Test Partner'),
    ),
    tickets: [
      Ticket(
        id: 'test-ticket-1',
        name: 'General',
        price: 15000,
        createdAt: referenceTime,
        updatedAt: referenceTime,
      ),
    ],
  );
}

class _DataEventDetailController extends EventDetailController {
  _DataEventDetailController(this._event);
  final Event _event;

  @override
  FutureOr<Event> build(String eventId) async => _event;
}

class _GuestAdmissionController extends EventAdmissionController {
  @override
  FutureOr<AdmissionState> build(Event event) async {
    return AdmissionState(status: EventAdmissionStatus.guest);
  }
}

class _FakePolicyRepository implements PolicyRepository {
  const _FakePolicyRepository({
    this.gracePeriodHours = 2,
    this.cutoffDays = 7,
    this.returnNull = false,
  });

  final int gracePeriodHours;
  final int cutoffDays;
  final bool returnNull;

  @override
  Future<Map<String, dynamic>?> getRefundPolicy() async {
    if (returnNull) return null;
    return {'grace_period_hours': gracePeriodHours, 'cutoff_days': cutoffDays};
  }
}
