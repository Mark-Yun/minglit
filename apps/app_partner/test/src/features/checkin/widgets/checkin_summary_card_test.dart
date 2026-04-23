import 'package:app_partner/src/features/checkin/widgets/checkin_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('CheckinSummaryCard', () {
    testWidgets('체크인 숫자와 분수 표시', (tester) async {
      await tester.pumpWidget(
        _wrap(const CheckinSummaryCard(checkedIn: 23, total: 50)),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('23'), findsOneWidget);
      expect(find.text('/50'), findsOneWidget);
      expect(find.text('46%'), findsOneWidget);
    });

    testWidgets('total=0이면 0/0 표시 + "아직 발급된 티켓이 없습니다"', (tester) async {
      await tester.pumpWidget(
        _wrap(const CheckinSummaryCard(checkedIn: 0, total: 0)),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('0'), findsOneWidget);
      expect(find.text('/0'), findsOneWidget);
      expect(find.text('아직 발급된 티켓이 없습니다'), findsOneWidget);
    });

    testWidgets('isLoading=true이면 MinglitSkeleton 표시', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CheckinSummaryCard(checkedIn: 0, total: 0, isLoading: true),
        ),
      );
      await tester.pump();

      expect(find.byType(MinglitSkeleton), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('isOffline=true이면 "캐시됨" 뱃지 표시', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CheckinSummaryCard(
            checkedIn: 10,
            total: 50,
            isOffline: true,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('캐시됨'), findsOneWidget);
      // percent 대신 badge가 표시되므로 퍼센트 텍스트는 없음
      expect(find.text('20%'), findsNothing);
    });

    testWidgets('90% 이상이면 error 색 progress bar', (tester) async {
      await tester.pumpWidget(
        _wrap(const CheckinSummaryCard(checkedIn: 46, total: 50)),
      );
      await tester.pump(const Duration(seconds: 1));

      // progress bar 존재 확인
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      // 92% → error 색
      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      final scheme = Theme.of(tester.element(find.byType(LinearProgressIndicator))).colorScheme;
      expect(
        (progressBar.valueColor as AlwaysStoppedAnimation<Color?>).value,
        scheme.error,
      );
    });

    testWidgets('Semantics 라벨 포함', (tester) async {
      await tester.pumpWidget(
        _wrap(const CheckinSummaryCard(checkedIn: 23, total: 50)),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.bySemanticsLabel(RegExp(r'전체 체크인 23명 중 50명')),
        findsOneWidget,
      );
    });

    testWidgets('lastUpdated가 null이면 "업데이트 중" 표시', (tester) async {
      await tester.pumpWidget(
        _wrap(const CheckinSummaryCard(checkedIn: 5, total: 20)),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('업데이트 중'), findsOneWidget);
    });

    testWidgets('lastUpdated가 30초 전이면 "방금 전 업데이트"', (tester) async {
      final recent = DateTime.now().subtract(const Duration(seconds: 30));
      await tester.pumpWidget(
        _wrap(
          CheckinSummaryCard(checkedIn: 5, total: 20, lastUpdated: recent),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('방금 전 업데이트'), findsOneWidget);
    });
  });
}
