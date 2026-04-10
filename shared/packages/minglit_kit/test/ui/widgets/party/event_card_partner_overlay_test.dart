// Fix #1214: showPartnerOverlay=false 시 파트너 오버레이가 숨겨지는지 검증
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

  const partner = Partner(id: 'partner-1', name: '밍글릿 라운지');

  final party = Party(
    id: 'party-1',
    partnerId: 'partner-1',
    title: '금요일 네트워킹',
    createdAt: baseTime,
    updatedAt: baseTime,
    partner: partner,
  );

  final event = Event(
    id: 'event-1',
    partyId: 'party-1',
    startTime: baseTime,
    endTime: baseTime.add(const Duration(hours: 3)),
    createdAt: baseTime,
    updatedAt: baseTime,
    currentParticipants: 5,
    party: party,
  );

  Widget buildCard(Event e, {bool showPartnerOverlay = true}) {
    return MaterialApp(
      theme: MinglitTheme.materialTheme,
      home: Scaffold(
        body: MinglitEventCard(
          event: e,
          currentTime: fiveDaysBefore,
          showPartnerOverlay: showPartnerOverlay,
        ),
      ),
    );
  }

  testWidgets('파트너 이름이 표시된다 — showPartnerOverlay: true (기본값)', (tester) async {
    await tester.pumpWidget(buildCard(event));
    await tester.pump();

    expect(find.text('밍글릿 라운지'), findsOneWidget);
  });

  testWidgets('파트너 이름이 숨겨진다 — showPartnerOverlay: false (파트너 상세 컨텍스트)', (tester) async {
    await tester.pumpWidget(buildCard(event, showPartnerOverlay: false));
    await tester.pump();

    // Fix #1214: 파트너 상세 페이지에서는 파트너 배지가 표시되지 않아야 한다.
    expect(find.text('밍글릿 라운지'), findsNothing);
  });

  testWidgets('파트너가 null이면 showPartnerOverlay 값과 무관하게 오버레이 없음', (tester) async {
    final partyNoPartner = Party(
      id: 'party-1',
      partnerId: 'partner-1',
      title: '금요일 네트워킹',
      createdAt: baseTime,
      updatedAt: baseTime,
      // partner intentionally omitted
    );
    final eventNoPartner = Event(
      id: 'event-2',
      partyId: 'party-1',
      startTime: baseTime,
      endTime: baseTime.add(const Duration(hours: 3)),
      createdAt: baseTime,
      updatedAt: baseTime,
      currentParticipants: 5,
      party: partyNoPartner,
    );

    await tester.pumpWidget(buildCard(eventNoPartner));
    await tester.pump();

    expect(find.text('밍글릿 라운지'), findsNothing);
  });
}
