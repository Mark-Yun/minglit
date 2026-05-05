// Ref #2224: Smoke — EventDetailPage spec 준수 검증
//
// Tab 구조 제거 + AppBar 타이틀 "이벤트 상세" + 참가 현황 섹션 렌더링을 검증한다.
import 'dart:async';

import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/event/detail/event_application_controller.dart';
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
    maxParticipants: 20,
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

  group('EventDetailPage (Fix #2224)', () {
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

    testWidgets('심사 대기 건이 있으면 "처리하기" 링크가 표시된다', (tester) async {
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

      expect(find.textContaining('처리하기'), findsOneWidget);
    });

    testWidgets('심사 대기 건이 없으면 "처리하기" 링크가 없다', (tester) async {
      await tester.pumpWidget(buildWidget(applications: []));
      await tester.pumpAndSettle();

      expect(find.textContaining('처리하기'), findsNothing);
    });
  });
}
