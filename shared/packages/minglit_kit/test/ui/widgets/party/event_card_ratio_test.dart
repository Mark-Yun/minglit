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
    title: '비율 테스트 파티',
    createdAt: baseTime,
    updatedAt: baseTime,
  );

  testWidgets('Fix #1382: event card image uses 2:1 aspect ratio', (
    tester,
  ) async {
    final event = Event(
      id: 'e-ratio',
      partyId: 'party-1',
      startTime: baseTime,
      endTime: baseTime.add(const Duration(hours: 2)),
      createdAt: baseTime,
      updatedAt: baseTime,
      currentParticipants: 5,
      party: party,
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

    // Fix #1382: 이벤트 카드의 이미지 비율이 2:1이어야 한다
    final ratioWidgets = tester
        .widgetList<AspectRatio>(find.byType(AspectRatio))
        .toList();
    expect(
      ratioWidgets.any((w) => (w.aspectRatio - 2.0).abs() < 0.01),
      isTrue,
      reason: 'AspectRatio 2:1 위젯이 카드 안에 존재해야 한다',
    );
  });

  testWidgets('Fix #1382: skeleton card uses 2:1 aspect ratio', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: MinglitTheme.materialTheme,
        home: const Scaffold(
          body: MinglitEventCard.loading(),
        ),
      ),
    );
    await tester.pump();

    // Fix #1382: 스켈레톤 카드도 2:1 비율이어야 한다
    final ratioWidgets = tester
        .widgetList<AspectRatio>(find.byType(AspectRatio))
        .toList();
    expect(
      ratioWidgets.any((w) => (w.aspectRatio - 2.0).abs() < 0.01),
      isTrue,
      reason: '스켈레톤 카드의 AspectRatio도 2:1이어야 한다',
    );
  });
}
