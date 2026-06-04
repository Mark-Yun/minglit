import 'package:app_partner/src/features/home/widgets/event_action_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

Event _makeEvent({
  required String phase,
  int currentParticipants = 3,
  int maxParticipants = 10,
  String partyId = 'p1',
  String? title,
}) {
  final now = DateTime.now();

  // Set startTime/endTime so that getEventPhase() returns the expected phase.
  final DateTime startTime;
  final DateTime endTime;
  switch (phase) {
    case 'recruiting':
      // > 7 days until start
      startTime = now.add(const Duration(days: 8));
      endTime = now.add(const Duration(days: 8, hours: 2));
    case 'preStart':
      // T-7 through T-30m
      startTime = now.add(const Duration(days: 3));
      endTime = now.add(const Duration(days: 3, hours: 2));
    case 'checkinReady':
      // T-30m through start
      startTime = now.add(const Duration(minutes: 20));
      endTime = now.add(const Duration(hours: 3));
    case 'live':
      // started but not ended
      startTime = now.subtract(const Duration(hours: 1));
      endTime = now.add(const Duration(hours: 2));
    case 'ended':
      // ended within 24 hours
      startTime = now.subtract(const Duration(hours: 3));
      endTime = now.subtract(const Duration(hours: 1));
    default:
      startTime = now.add(const Duration(minutes: 90));
      endTime = now.add(const Duration(hours: 3));
  }

  return Event(
    id: 'e1',
    partyId: partyId,
    startTime: startTime,
    endTime: endTime,
    createdAt: now,
    updatedAt: now,
    currentParticipants: currentParticipants,
    maxParticipants: maxParticipants,
    title: title,
  );
}

void main() {
  group('EventActionCard', () {
    testWidgets(
      'recruiting phase shows "모집 중" badge and "신청 현황 보기" CTA',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EventActionCard(
                event: _makeEvent(phase: 'recruiting'),
                onMainAction: () {},
                onSecondaryAction1: () {},
                onSecondaryAction2: () {},
              ),
            ),
          ),
        );
        expect(find.textContaining('모집 중'), findsOneWidget);
        expect(find.text('신청 현황 보기'), findsOneWidget);
      },
    );

    testWidgets(
      'pre-start phase shows "체크인 대기" badge and "참가자 리스트" CTA',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EventActionCard(
                event: _makeEvent(phase: 'preStart'),
                onMainAction: () {},
                onSecondaryAction1: () {},
                onSecondaryAction2: () {},
              ),
            ),
          ),
        );
        expect(find.textContaining('체크인 대기'), findsOneWidget);
        expect(find.text('참가자 리스트'), findsOneWidget);
      },
    );

    testWidgets(
      'checkin-ready phase shows "체크인 가능" badge and "참가자 체크인" CTA',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EventActionCard(
                event: _makeEvent(phase: 'checkinReady'),
                onMainAction: () {},
                onSecondaryAction1: () {},
                onSecondaryAction2: null,
              ),
            ),
          ),
        );
        expect(find.textContaining('체크인 가능'), findsOneWidget);
        expect(find.text('참가자 체크인'), findsOneWidget);
      },
    );

    testWidgets(
      'live phase shows "LIVE" badge and "참가자 체크인" CTA',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EventActionCard(
                event: _makeEvent(phase: 'live'),
                onMainAction: () {},
                onSecondaryAction1: () {},
                onSecondaryAction2: null,
              ),
            ),
          ),
        );
        expect(find.textContaining('LIVE'), findsOneWidget);
        expect(find.text('참가자 체크인'), findsOneWidget);
      },
    );

    testWidgets(
      'ended phase shows "종료" badge and "다음 회차 만들기" CTA',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EventActionCard(
                event: _makeEvent(phase: 'ended'),
                onMainAction: () {},
                onSecondaryAction1: () {},
                onSecondaryAction2: null,
              ),
            ),
          ),
        );
        expect(find.textContaining('종료'), findsOneWidget);
        expect(find.text('다음 회차 만들기'), findsOneWidget);
      },
    );

    testWidgets('shows capacity bar with currentParticipants/maxParticipants', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventActionCard(
              event: _makeEvent(
                phase: 'recruiting',
                currentParticipants: 4,
              ),
              onMainAction: () {},
              onSecondaryAction1: () {},
              onSecondaryAction2: () {},
            ),
          ),
        ),
      );
      expect(find.text('4/10명'), findsOneWidget);
    });

    testWidgets('onMainAction callback is invoked when CTA tapped', (
      tester,
    ) async {
      var called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventActionCard(
              event: _makeEvent(phase: 'recruiting'),
              onMainAction: () => called = true,
              onSecondaryAction1: () {},
              onSecondaryAction2: () {},
            ),
          ),
        ),
      );
      await tester.tap(find.text('신청 현황 보기'));
      expect(called, isTrue);
    });
  });

  group('EventActionCardEmpty', () {
    testWidgets('hasParties=true shows "이벤트 만들기" button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventActionCardEmpty(
              hasParties: true,
              onCreateEvent: () {},
              onCreateParty: () {},
            ),
          ),
        ),
      );
      expect(find.text('이벤트 만들기'), findsOneWidget);
    });

    testWidgets('hasParties=false shows "파티 만들기" button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventActionCardEmpty(
              hasParties: false,
              onCreateEvent: () {},
              onCreateParty: () {},
            ),
          ),
        ),
      );
      expect(find.text('파티 만들기'), findsOneWidget);
    });
  });
}
