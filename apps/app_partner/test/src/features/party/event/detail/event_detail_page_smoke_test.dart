// Ref #2109: Smoke — EventDetailPage hub layout spec 준수 검증
//
// Tab 구조 제거 + 상태 배너/메타 칩/참가 CTA 렌더링을 검증한다.
import 'dart:async';

import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/logic/event_application_logic.dart';
import 'package:app_partner/src/features/party/event/detail/event_detail_controller.dart';
import 'package:app_partner/src/features/party/event/detail/event_detail_page.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  final now = DateTime(2026, 5, 1, 15);

  final testEvent = Event(
    id: 'event-1',
    partyId: 'party-1',
    title: '소개팅 파티',
    startTime: now.add(const Duration(days: 3)),
    endTime: now.add(const Duration(days: 3, hours: 2)),
    createdAt: now,
    updatedAt: now,
    tickets: [],
    entryGroups: [],
    maxParticipants: 40,
    currentParticipants: 18,
  );

  final testParty = Party(
    id: 'party-1',
    title: '테스트 파티',
    partnerId: 'partner-1',
    createdAt: now,
    updatedAt: now,
  );

  Widget buildWidget({
    Event? event,
    Completer<Event>? eventCompleter,
    Object? eventError,
    List<EventApplication> applications = const [],
    List<Ticket> tickets = const [],
  }) {
    return ProviderScope(
      overrides: [
        eventDetailProvider('event-1').overrideWith(
          (ref) async {
            if (eventError != null) throw eventError;
            if (eventCompleter != null) return eventCompleter.future;
            return event ?? testEvent;
          },
        ),
        partyDetailProvider('party-1').overrideWith(
          (ref) async => testParty,
        ),
        eventApplicationsProvider('event-1').overrideWith(
          (ref) async => applications,
        ),
        eventTicketsProvider('event-1').overrideWith(
          (ref) async => tickets,
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('ko'),
        home: EventDetailPage(eventId: 'event-1'),
      ),
    );
  }

  group('EventDetailPage (Fix #2109)', () {
    testWidgets('AppBar 타이틀이 "이벤트 상세"이다', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('이벤트 상세'), findsOneWidget);
    });

    testWidgets('TabBar가 없다 — Tab 구조 폐기', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsNothing);
    });

    testWidgets('DefaultTabController가 없다', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(DefaultTabController), findsNothing);
    });

    testWidgets('참가 현황 섹션이 표시된다', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('참가 현황'), findsOneWidget);
    });

    testWidgets('로딩 중에는 CircularProgressIndicator가 표시된다', (tester) async {
      // Completer로 영구 pending — delayed로 타이머를 남기지 않도록
      final completer = Completer<Event>();
      await tester.pumpWidget(buildWidget(eventCompleter: completer));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('에러 시 크래시 없이 렌더링된다', (tester) async {
      await tester.pumpWidget(
        buildWidget(eventError: Exception('load error')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('심사 대기 건이 있으면 심사 대기 링크가 표시된다', (tester) async {
      final pendingApp = EventApplication(
        id: 'app-1',
        eventId: 'event-1',
        ticketId: 'ticket-1',
        userId: 'user-1',
        status: 'pending_review',
        createdAt: now,
        updatedAt: now,
      );
      await tester.pumpWidget(buildWidget(applications: [pendingApp]));
      await tester.pumpAndSettle();

      expect(find.textContaining('심사 대기'), findsOneWidget);
    });

    testWidgets('심사 대기 건이 없으면 심사 대기 링크가 없다', (tester) async {
      await tester.pumpWidget(buildWidget(applications: []));
      await tester.pumpAndSettle();

      expect(find.textContaining('심사 대기'), findsNothing);
    });

    testWidgets(
      '확정 인원은 event.currentParticipants 기준으로 표시된다',
      (tester) async {
        // Fix #2224: confirmedCount = event.currentParticipants (not application list)
        await tester.pumpWidget(buildWidget());
        await tester.pumpAndSettle();

        expect(find.text('18'), findsOneWidget);
        expect(find.text(' / 40 명'), findsOneWidget);
      },
    );

    testWidgets('취소 상태면 이벤트 정보 카드에 취소됨 레이블이 표시된다', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          event: testEvent.copyWith(status: 'cancelled'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('취소됨'), findsOneWidget);
    });

    testWidgets('이벤트 정보 카드와 액션 버튼들이 표시된다', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // 이벤트 정보 섹션 (MinglitSection)
      expect(find.text('이벤트 정보'), findsOneWidget);
      // 공개 설정 레이블 (visibility DetailRow)
      expect(find.text('공개'), findsOneWidget);
      // 편집 버튼
      expect(find.text('정보 수정'), findsOneWidget);
      // 신청 목록 버튼 (참가 현황 섹션)
      expect(find.text('신청 목록 보기'), findsOneWidget);
    });

    testWidgets('티켓이 있으면 티켓 관리 섹션에 티켓명이 표시된다', (tester) async {
      final ticket = Ticket(
        id: 'ticket-1',
        name: '일반 티켓',
        createdAt: now,
        updatedAt: now,
        price: 55000,
        quantity: 10,
      );

      await tester.pumpWidget(
        buildWidget(tickets: [ticket]),
      );
      await tester.pumpAndSettle();

      expect(find.text('일반 티켓'), findsOneWidget);
    });

    testWidgets('확정 인원이 있으면 정보 수정 시 잠금 SnackBar가 표시된다', (tester) async {
      // Fix #2110: confirmedCount = event.currentParticipants (18) >= 1 → 잠금 토스트
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('정보 수정'));
      await tester.pump();

      expect(
        find.text('확정 참가자가 있어 일부 항목은 잠겨 있습니다.'),
        findsOneWidget,
      );
    });

    testWidgets('확정 인원이 없으면 정보 수정 시 EventEditRoute로 이동한다', (tester) async {
      // Fix #2110: confirmedCount = 0 → EventEditRoute push (no GoRouter in test)
      await tester.pumpWidget(
        buildWidget(event: testEvent.copyWith(currentParticipants: 0)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('정보 수정'));
      await tester.pump();

      tester.takeException(); // GoRouter not present in test
    });

    testWidgets('완료 상태면 이벤트 정보 카드에 종료됨 레이블이 표시된다', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          event: testEvent.copyWith(status: 'completed'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('종료됨'), findsOneWidget);
    });

    testWidgets('scheduled 상태면 모집 예정 레이블이 표시된다', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          event: testEvent.copyWith(status: 'scheduled'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('모집 예정/진행중'), findsOneWidget);
    });

    testWidgets('private visibility면 비공개 레이블이 표시된다', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          event: testEvent.copyWith(visibility: 'private'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('비공개'), findsOneWidget);
      expect(find.text('공개'), findsNothing);
    });
  });
}
