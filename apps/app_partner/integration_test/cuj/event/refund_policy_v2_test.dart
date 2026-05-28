// CUJ tests — event / refund-policy-v2 (app_partner)
//
// 대응 spec: docs/features/event/refund-policy-v2/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).
//
// 커버 범위:
//   - CUJ 4-1: 파트너 환불 요청 알림/목록 노출
//   - CUJ 4-2: 환불 요청 상세 확인 + 승인
//   - CUJ 4-3: 환불 요청 거절

import 'package:app_partner/src/features/application/event_application_detail_page.dart';
import 'package:app_partner/src/features/party/event/detail/event_application_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../_engine/cuj_test.dart';

class _MockEventRepository extends Mock implements EventRepository {}

class _MockVerificationRepository extends Mock
    implements VerificationRepository {}

final _now = DateTime(2026, 6, 1, 12);

Event _makeEvent({
  String id = 'event-1',
  String title = '금요일 와인 모임 #42',
}) {
  return Event(
    id: id,
    partyId: 'party-1',
    title: title,
    startTime: _now.add(const Duration(days: 10)),
    endTime: _now.add(const Duration(days: 10, hours: 2)),
    createdAt: _now,
    updatedAt: _now,
    entryGroups: const [],
  );
}

UserProfile _makeUser({
  String id = 'user-1',
  String name = '김민수',
  String username = '환불요청자',
}) {
  return UserProfile(
    id: id,
    name: name,
    username: username,
    createdAt: _now,
    updatedAt: _now,
  );
}

EventApplication _makeApplication({
  required String id,
  String status = 'cancelled',
  String? cancellationReason,
  String? rejectionReason,
  int? paymentAmount = 30000,
  DateTime? paidAt,
  DateTime? refundedAt,
  UserProfile? user,
}) {
  return EventApplication(
    id: id,
    eventId: 'event-1',
    ticketId: 'ticket-1',
    userId: 'user-1',
    status: status,
    paymentAmount: paymentAmount,
    cancellationReason: cancellationReason,
    rejectionReason: rejectionReason,
    paidAt: paidAt,
    refundedAt: refundedAt,
    createdAt: _now.subtract(const Duration(hours: 2)),
    updatedAt: _now.subtract(const Duration(hours: 1)),
    user: user ?? _makeUser(),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late _MockEventRepository mockEventRepo;
  late _MockVerificationRepository mockVerificationRepo;

  setUp(() {
    mockEventRepo = _MockEventRepository();
    mockVerificationRepo = _MockVerificationRepository();

    when(
      () => mockEventRepo.getEntryGroupParticipantCounts(any()),
    ).thenAnswer((_) async => []);
    when(
      () => mockVerificationRepo.getSubmissionByApplicationId(any()),
    ).thenAnswer((_) async => null);
    when(
      () => mockVerificationRepo.updateApplicationStatus(
        applicationId: any(named: 'applicationId'),
        status: any(named: 'status'),
        rejectionReason: any(named: 'rejectionReason'),
      ),
    ).thenAnswer((_) async {});
  });

  List<dynamic> base() => [
    eventRepositoryProvider.overrideWithValue(mockEventRepo),
    verificationRepositoryProvider.overrideWithValue(mockVerificationRepo),
  ];

  cujGroup('4-1', '파트너 환불 요청 알림', () {
    cujCase(
      'happy: 환불 탭에서 요청 카드(신청자/사유) 확인',
      app: const EventApplicationListPage(eventId: 'event-1'),
      overrides: () {
        final event = _makeEvent();
        final refundApp = _makeApplication(
          id: 'app-refund-1',
          cancellationReason: '개인 일정 변경',
          refundedAt: _now.subtract(const Duration(hours: 3)),
        );
        when(() => mockEventRepo.getEventById('event-1')).thenAnswer(
          (_) async => event,
        );
        when(
          () => mockEventRepo.getApplicationsByEventId('event-1'),
        ).thenAnswer((_) async => [refundApp]);
        return base();
      },
      body: (t) async {
        await t.pumpAndSettle();
        await t.tap(find.text('환불'));
        await t.pumpAndSettle();

        expect(find.text('환***'), findsOneWidget);
        expect(find.text('개인 일정 변경'), findsOneWidget);
      },
    );
  });

  cujGroup('4-2', '파트너 환불 요청 상세 + 승인', () {
    cujCase(
      'happy: 상세 화면에서 승인 탭 → 승인 상태 업데이트 호출',
      app: const EventApplicationDetailPage(applicationId: 'app-approve'),
      overrides: () {
        final app = _makeApplication(
          id: 'app-approve',
          status: 'pending_review',
          paidAt: _now.subtract(const Duration(days: 1)),
        );
        when(
          () => mockEventRepo.getApplicationById('app-approve'),
        ).thenAnswer((_) async => app);
        return base();
      },
      body: (t) async {
        await t.pumpAndSettle();

        expect(find.text('결제금액'), findsOneWidget);
        await t.tap(find.widgetWithText(FilledButton, '승인'));
        await t.pumpAndSettle();

        verify(
          () => mockVerificationRepo.updateApplicationStatus(
            applicationId: 'app-approve',
            status: 'approved',
          ),
        ).called(1);
      },
    );
  });

  cujGroup('4-3', '파트너 환불 요청 거절', () {
    cujCase(
      'happy: 거절 사유 입력 후 제출 → 거절 상태 업데이트 호출',
      app: const EventApplicationDetailPage(applicationId: 'app-reject'),
      overrides: () {
        final app = _makeApplication(
          id: 'app-reject',
          status: 'pending_review',
          paidAt: _now.subtract(const Duration(days: 1)),
        );
        when(
          () => mockEventRepo.getApplicationById('app-reject'),
        ).thenAnswer((_) async => app);
        return base();
      },
      body: (t) async {
        await t.pumpAndSettle();

        await t.tap(find.widgetWithText(OutlinedButton, '거절'));
        await t.pumpAndSettle();
        expect(find.text('거절 사유'), findsOneWidget);

        await t.enterText(find.byType(TextField), '파트너 검토 후 거절');
        await t.tap(find.widgetWithText(TextButton, '거절'));
        await t.pumpAndSettle();

        verify(
          () => mockVerificationRepo.updateApplicationStatus(
            applicationId: 'app-reject',
            status: 'rejected',
            rejectionReason: '파트너 검토 후 거절',
          ),
        ).called(1);
      },
    );
  });
}
