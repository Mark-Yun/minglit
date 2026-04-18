// Fix #478: 이벤트 카드 상태별 시각화 강화 — 상태 분기 로직 위젯 테스트
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  // Fixed base time: event starts 2026-06-15 19:00
  final baseTime = DateTime(2026, 6, 15, 19);
  final fiveDaysBefore = DateTime(2026, 6, 10, 12);
  const partner = Partner(id: 'partner-1', name: '밍글릿 라운지');

  final party = Party(
    id: 'party-1',
    partnerId: 'partner-1',
    title: '금요일 네트워킹',
    createdAt: baseTime,
    updatedAt: baseTime,
    partner: partner,
  );

  Widget buildCard(
    Event event, {
    required DateTime currentTime,
    bool showPartnerOverlay = true,
  }) {
    return MaterialApp(
      theme: MinglitTheme.materialTheme,
      home: Scaffold(
        body: MinglitEventCard(
          event: event,
          currentTime: currentTime,
          showPartnerOverlay: showPartnerOverlay,
        ),
      ),
    );
  }

  group('EventCard state visualization', () {
    testWidgets('soldOut state shows 마감 overlay', (tester) async {
      // currentParticipants >= maxParticipants → soldOut
      final soldOutEvent = Event(
        id: 'e-soldout',
        partyId: 'party-1',
        startTime: baseTime,
        endTime: baseTime.add(const Duration(hours: 3)),
        createdAt: baseTime,
        updatedAt: baseTime,
        currentParticipants: 20,
        // maxParticipants defaults to 20 — explicitly set to match for soldOut
        maxParticipants: 20, // ignore: avoid_redundant_argument_values
        party: party,
      );

      // currentTime is 5 days before event (difference > 0, not ended)
      final fiveDaysBefore = DateTime(2026, 6, 10, 12);

      await tester.pumpWidget(
        buildCard(soldOutEvent, currentTime: fiveDaysBefore),
      );
      await tester.pump();

      // Fix #478: "마감" overlay badge must be visible when sold out
      expect(find.text('마감'), findsWidgets);

      // Fix #1558: Semantics label must include "만석, 참여 불가" so screen readers convey sold-out state
      // (시각 배지는 "마감", 스크린리더 announce는 #996 원래 용어인 "만석, 참여 불가")
      final soldOutSemantics = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where(
            (w) =>
                (w.properties.label ?? '').contains('만석, 참여 불가') &&
                (w.properties.label ?? '').contains('이벤트:'),
          );
      expect(
        soldOutSemantics,
        isNotEmpty,
        reason: 'sold-out card Semantics label must contain "만석, 참여 불가"',
      );
    });

    testWidgets('ended state applies grayscale ColorFiltered', (tester) async {
      // difference < 0 → ended (event in the past)
      final pastEvent = Event(
        id: 'e-ended',
        partyId: 'party-1',
        startTime: baseTime,
        endTime: baseTime.add(const Duration(hours: 3)),
        createdAt: baseTime,
        updatedAt: baseTime,
        currentParticipants: 5,
        party: party,
      );

      // currentTime is 2 days after event start → difference == -2 → ended
      final twoDaysAfter = DateTime(2026, 6, 17, 12);

      await tester.pumpWidget(buildCard(pastEvent, currentTime: twoDaysAfter));
      await tester.pump();

      // Fix #478: ColorFiltered with BlendMode.saturation for grayscale
      final colorFilteredWidgets = tester.widgetList<ColorFiltered>(
        find.byType(ColorFiltered),
      );
      expect(
        colorFilteredWidgets.any(
          (w) =>
              w.colorFilter ==
              const ColorFilter.mode(Colors.grey, BlendMode.saturation),
        ),
        isTrue,
        reason: 'ended state should apply grayscale ColorFilter',
      );
    });

    testWidgets('today state shows amber border', (tester) async {
      // difference == 0 → today
      final todayEvent = Event(
        id: 'e-today',
        partyId: 'party-1',
        startTime: baseTime,
        endTime: baseTime.add(const Duration(hours: 3)),
        createdAt: baseTime,
        updatedAt: baseTime,
        currentParticipants: 5,
        party: party,
      );

      // currentTime is on the same day, a few hours before event
      final sameDay = DateTime(2026, 6, 15, 10);

      await tester.pumpWidget(buildCard(todayEvent, currentTime: sameDay));
      await tester.pump();

      // Fix #478: A Container with amber border must exist for today state
      final containers = tester.widgetList<Container>(find.byType(Container));
      final hasBorder = containers.any((c) {
        final decoration = c.decoration;
        if (decoration is BoxDecoration) {
          final border = decoration.border;
          if (border is Border) {
            return border.top.color == MinglitColors.secondary &&
                border.top.width == 2.0;
          }
        }
        return false;
      });
      expect(hasBorder, isTrue, reason: 'today state should show amber border');
    });

    testWidgets('normal state has no 마감 overlay and no saturation filter', (
      tester,
    ) async {
      // difference > 0, currentParticipants < maxParticipants → normal
      final normalEvent = Event(
        id: 'e-normal',
        partyId: 'party-1',
        startTime: baseTime,
        endTime: baseTime.add(const Duration(hours: 3)),
        createdAt: baseTime,
        updatedAt: baseTime,
        currentParticipants: 8,
        party: party,
      );

      // currentTime is 5 days before event
      final fiveDaysBefore = DateTime(2026, 6, 10, 12);

      await tester.pumpWidget(
        buildCard(normalEvent, currentTime: fiveDaysBefore),
      );
      await tester.pump();

      // No "마감" overlay for normal state
      expect(find.text('마감'), findsNothing);

      // No saturation ColorFilter for normal state
      final colorFilteredWidgets = tester.widgetList<ColorFiltered>(
        find.byType(ColorFiltered),
      );
      expect(
        colorFilteredWidgets.any(
          (w) =>
              w.colorFilter ==
              const ColorFilter.mode(Colors.grey, BlendMode.saturation),
        ),
        isFalse,
        reason: 'normal state should not apply grayscale ColorFilter',
      );
    });

    testWidgets('partner overlay can be hidden in partner-owned context', (
      tester,
    ) async {
      final event = Event(
        id: 'e-partner-hidden',
        partyId: 'party-1',
        startTime: baseTime,
        endTime: baseTime.add(const Duration(hours: 3)),
        createdAt: baseTime,
        updatedAt: baseTime,
        currentParticipants: 8,
        party: party,
      );

      await tester.pumpWidget(
        buildCard(
          event,
          currentTime: fiveDaysBefore,
          showPartnerOverlay: false,
        ),
      );
      await tester.pump();

      expect(find.text(partner.name), findsNothing);
    });

    testWidgets('partner overlay is shown by default', (tester) async {
      final event = Event(
        id: 'e-partner-visible',
        partyId: 'party-1',
        startTime: baseTime,
        endTime: baseTime.add(const Duration(hours: 3)),
        createdAt: baseTime,
        updatedAt: baseTime,
        currentParticipants: 8,
        party: party,
      );

      await tester.pumpWidget(
        buildCard(event, currentTime: fiveDaysBefore),
      );
      await tester.pump();

      expect(find.text(partner.name), findsOneWidget);
    });
  });

  // Fix #996: 카드 전체를 하나의 시맨틱 노드로 병합하여 스크린 리더가
  // 파편화된 정보를 읽지 않도록 함. 회귀 방지용 Semantics 테스트.
  group('EventCard Semantics', () {
    testWidgets(
      'tappable card wraps with Semantics(button, descriptive label)',
      (
        tester,
      ) async {
        final event = Event(
          id: 'e-semantics',
          partyId: 'party-1',
          startTime: baseTime,
          endTime: baseTime.add(const Duration(hours: 3)),
          createdAt: baseTime,
          updatedAt: baseTime,
          currentParticipants: 8,
          party: party,
          title: '금요일 네트워킹',
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: MinglitTheme.materialTheme,
            home: Scaffold(
              body: MinglitEventCard(
                event: event,
                currentTime: fiveDaysBefore,
                onTap: () {},
              ),
            ),
          ),
        );
        await tester.pump();

        final matches = find
            .byWidgetPredicate(
              (w) =>
                  w is Semantics &&
                  (w.properties.label ?? '').startsWith('이벤트: 금요일 네트워킹') &&
                  w.properties.button == true &&
                  w.excludeSemantics,
            )
            .evaluate();

        expect(
          matches,
          isNotEmpty,
          reason:
              'tappable card must wrap with Semantics('
              'label: "이벤트: ...", button: true, excludeSemantics: true)',
        );
        final wrapper = matches.first.widget as Semantics;
        expect(wrapper.properties.label, contains('참가자 8/20명'));
        expect(
          wrapper.properties.onTap,
          isNotNull,
          reason:
              'tappable card Semantics must expose onTap so screen reader '
              'users can activate the card',
        );
      },
    );

    testWidgets('non-tappable card omits button role', (tester) async {
      final readonlyParty = Party(
        id: 'party-readonly',
        partnerId: 'partner-1',
        title: '읽기 전용 카드',
        createdAt: baseTime,
        updatedAt: baseTime,
        partner: partner,
      );
      final event = Event(
        id: 'e-semantics-readonly',
        partyId: readonlyParty.id,
        startTime: baseTime,
        endTime: baseTime.add(const Duration(hours: 3)),
        createdAt: baseTime,
        updatedAt: baseTime,
        currentParticipants: 5,
        party: readonlyParty,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: MinglitTheme.materialTheme,
          home: Scaffold(
            body: MinglitEventCard(
              event: event,
              currentTime: fiveDaysBefore,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              (w.properties.label ?? '').startsWith('이벤트: 읽기 전용 카드') &&
              w.properties.button != true,
        ),
        findsOneWidget,
        reason: 'non-tappable card must not announce button role',
      );
    });
  });
}
