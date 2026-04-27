// Fix #72 회귀 방지: visibility=null 전달 시 크래시 방어
// PartyStatusEditSheet는 currentVisibility 기본값 'public'으로 null 방어.
import 'package:app_partner/src/features/party/widgets/party_status_edit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap({
    String currentStatus = 'active',
    ValueChanged<String>? onStatusSelected,
    String currentVisibility = 'public',
    ValueChanged<String>? onVisibilityChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PartyStatusEditSheet(
          currentStatus: currentStatus,
          onStatusSelected: onStatusSelected ?? (_) {},
          currentVisibility: currentVisibility,
          onVisibilityChanged: onVisibilityChanged,
        ),
      ),
    );
  }

  group('PartyStatusEditSheet — Fix #72 regression', () {
    testWidgets('기본값(public) visibility로 크래시 없이 렌더', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pump();

      expect(find.text('운영 상태 변경'), findsOneWidget);
      expect(find.text('비공개'), findsOneWidget);
    });

    testWidgets('visibility=public → 비공개 스위치 OFF', (tester) async {
      await tester.pumpWidget(
        wrap(),
      );
      await tester.pump();

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      final switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isFalse);
    });

    testWidgets('visibility=private → 비공개 스위치 ON', (tester) async {
      await tester.pumpWidget(
        wrap(currentVisibility: 'private'),
      );
      await tester.pump();

      final switchFinder = find.byType(Switch);
      final switchWidget = tester.widget<Switch>(switchFinder);
      expect(switchWidget.value, isTrue);
    });
  });

  group('PartyStatusEditSheet — 상태 선택', () {
    testWidgets('active 상태 탭 시 onStatusSelected 호출', (tester) async {
      String? selected;
      await tester.pumpWidget(
        wrap(
          currentStatus: 'draft',
          onStatusSelected: (v) => selected = v,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('운영중 (공개)'));
      await tester.pump();

      expect(selected, 'active');
    });

    testWidgets('draft 상태 탭 시 onStatusSelected 호출', (tester) async {
      String? selected;
      await tester.pumpWidget(
        wrap(
          onStatusSelected: (v) => selected = v,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('임시저장 (비공개)'));
      await tester.pump();

      expect(selected, 'draft');
    });

    testWidgets('closed 상태 탭 시 onStatusSelected 호출', (tester) async {
      String? selected;
      await tester.pumpWidget(
        wrap(
          onStatusSelected: (v) => selected = v,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('종료됨'));
      await tester.pump();

      expect(selected, 'closed');
    });
  });

  group('PartyStatusEditSheet — 공개 범위 변경', () {
    testWidgets('스위치 ON → onVisibilityChanged("private") 호출', (tester) async {
      String? changedTo;
      await tester.pumpWidget(
        wrap(
          onVisibilityChanged: (v) => changedTo = v,
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(changedTo, 'private');
    });

    testWidgets('스위치 OFF → onVisibilityChanged("public") 호출', (tester) async {
      String? changedTo;
      await tester.pumpWidget(
        wrap(
          currentVisibility: 'private',
          onVisibilityChanged: (v) => changedTo = v,
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(changedTo, 'public');
    });
  });
}
