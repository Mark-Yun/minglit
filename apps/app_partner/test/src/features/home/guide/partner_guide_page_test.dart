import 'package:app_partner/src/features/home/guide/partner_guide_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  group('PartnerGuidePage', () {
    testWidgets('renders guide topics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MinglitTheme.materialTheme,
          home: const PartnerGuidePage(),
        ),
      );

      expect(find.text('도움말'), findsOneWidget);
      expect(find.text('밍글릿 파트너 가이드'), findsOneWidget);
      expect(find.text('운영 현황'), findsOneWidget);
      expect(find.text('진행 중'), findsOneWidget);
      expect(find.text('이벤트 참가 승인 대기'), findsOneWidget);
      expect(find.text('진행 임박'), findsOneWidget);
      expect(find.text('모집 중인 이벤트'), findsOneWidget);
      expect(find.text('작성 중인 파티'), findsOneWidget);
    });

    testWidgets('opens topic sheet from row tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MinglitTheme.materialTheme,
          home: const PartnerGuidePage(),
        ),
      );

      await tester.tap(find.text('운영 현황'));
      await tester.pumpAndSettle();

      expect(find.text('이 숫자가 뭔가요?'), findsOneWidget);
      expect(find.text('확인'), findsOneWidget);
    });

    testWidgets('opens initial topic sheet from slug', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: MinglitTheme.materialTheme,
          home: const PartnerGuidePage(initialTopicSlug: 'dashboard-overview'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('이 숫자가 뭔가요?'), findsOneWidget);
    });
  });
}
