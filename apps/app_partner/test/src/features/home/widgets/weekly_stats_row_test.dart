import 'package:app_partner/src/features/home/widgets/weekly_stats_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeeklyStatsRow', () {
    testWidgets(
      'shows revenue, applications and checkin-rate columns with zero values',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: WeeklyStatsRow(
                totalRevenue: 0,
                totalApplications: 0,
                checkinRate: 0,
              ),
            ),
          ),
        );

        expect(find.text('매출'), findsOneWidget);
        expect(find.text('신청'), findsOneWidget);
        expect(find.text('체크인율'), findsOneWidget);
        expect(find.text('₩0'), findsOneWidget);
        expect(find.text('0'), findsOneWidget);
        expect(find.text('0%'), findsOneWidget);
      },
    );

    testWidgets(
      'shows green positive change text when change is greater than zero',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: WeeklyStatsRow(
                totalRevenue: 100000,
                totalApplications: 5,
                checkinRate: 80,
                revenueChange: 12,
              ),
            ),
          ),
        );

        expect(find.text('+12% ↑'), findsOneWidget);

        final changeText = tester.widget<Text>(find.text('+12% ↑'));
        expect(changeText.style?.color, isNotNull);
      },
    );

    testWidgets(
      'does not show change text when change is null',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: WeeklyStatsRow(
                totalRevenue: 50000,
                totalApplications: 3,
                checkinRate: 60,
              ),
            ),
          ),
        );

        // No change indicators should appear (no ↑ or ↓ arrows)
        expect(find.textContaining('↑'), findsNothing);
        expect(find.textContaining('↓'), findsNothing);
      },
    );
  });
}
