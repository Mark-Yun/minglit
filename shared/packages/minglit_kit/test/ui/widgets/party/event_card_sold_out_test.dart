import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  final baseTime = DateTime(2026, 6, 15, 19);
  final fiveDaysBefore = DateTime(2026, 6, 10, 12);

  final party = Party(
    id: 'party-1',
    partnerId: 'partner-1',
    title: '금요일 네트워킹',
    createdAt: baseTime,
    updatedAt: baseTime,
  );

  Widget buildCard(Event event) {
    return MaterialApp(
      theme: MinglitTheme.materialTheme,
      home: Scaffold(
        body: MinglitEventCard(
          event: event,
          currentTime: fiveDaysBefore,
        ),
      ),
    );
  }

  testWidgets('만석 텍스트가 표시된다 — 참가자가 최대 정원에 달했을 때', (tester) async {
    final soldOutEvent = Event(
      id: 'e-1',
      partyId: 'party-1',
      startTime: baseTime,
      endTime: baseTime.add(const Duration(hours: 3)),
      createdAt: baseTime,
      updatedAt: baseTime,
      currentParticipants: 20,
      party: party,
    );

    await tester.pumpWidget(buildCard(soldOutEvent));
    await tester.pump();

    // Fix #996: 만석 텍스트가 표시되어야 한다
    expect(find.text('만석'), findsOneWidget);
  });

  testWidgets('만석 텍스트가 표시되지 않는다 — 여석이 있을 때', (tester) async {
    final partialEvent = Event(
      id: 'e-2',
      partyId: 'party-1',
      startTime: baseTime,
      endTime: baseTime.add(const Duration(hours: 3)),
      createdAt: baseTime,
      updatedAt: baseTime,
      currentParticipants: 15,
      party: party,
    );

    await tester.pumpWidget(buildCard(partialEvent));
    await tester.pump();

    expect(find.text('만석'), findsNothing);
  });

  testWidgets('만석 상태에서 Semantics 라벨이 올바르다', (tester) async {
    // Fix #996: ensureSemantics()는 pumpWidget 전에 호출해야 semantics 트리가 활성화 상태로 빌드됨
    final semanticsHandle = tester.ensureSemantics();
    addTearDown(semanticsHandle.dispose);

    final soldOutEvent = Event(
      id: 'e-3',
      partyId: 'party-1',
      startTime: baseTime,
      endTime: baseTime.add(const Duration(hours: 3)),
      createdAt: baseTime,
      updatedAt: baseTime,
      currentParticipants: 20,
      party: party,
    );

    await tester.pumpWidget(buildCard(soldOutEvent));
    await tester.pump();

    // Fix #996: 만석 텍스트가 렌더링되어 있는지 확인
    expect(find.text('만석'), findsOneWidget);

    // Fix #996: 스크린 리더 라벨 값 자체를 검증
    expect(find.bySemanticsLabel('이벤트 만석, 참여 불가'), findsOneWidget);
  });
}
