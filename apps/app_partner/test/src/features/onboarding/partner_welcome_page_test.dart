import 'package:app_partner/src/features/onboarding/partner_welcome_page.dart';
import 'package:app_partner/src/features/onboarding/widgets/dot_indicator.dart';
import 'package:app_partner/src/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  Widget buildTestWidget() {
    return ProviderScope(
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const PartnerWelcomePage(),
            ),
            GoRoute(
              path: '/apply',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('Apply Page')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  group('PartnerWelcomePage', () {
    testWidgets('renders PageView', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('renders DotIndicator', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(DotIndicator), findsOneWidget);
    });

    testWidgets('CTA button "파트너 신청서 작성하기" is visible', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('파트너 신청서 작성하기'), findsOneWidget);
    });

    testWidgets('logout PopupMenuButton is present', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('first page content is visible on initial render', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('밍글릿 파트너가 되어보세요'), findsOneWidget);
    });

    testWidgets('DotIndicator starts at index 0', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final dotIndicator = tester.widget<DotIndicator>(
        find.byType(DotIndicator),
      );
      expect(dotIndicator.currentIndex, equals(0));
      expect(dotIndicator.totalCount, equals(4));
    });

    testWidgets('swipe left updates dot indicator to index 1', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Swipe left to go to page 2
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      final dotIndicator = tester.widget<DotIndicator>(
        find.byType(DotIndicator),
      );
      expect(dotIndicator.currentIndex, equals(1));
    });

    testWidgets('CTA button navigates to /apply', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('파트너 신청서 작성하기'));
      await tester.pumpAndSettle();

      expect(find.text('Apply Page'), findsOneWidget);
    });

    testWidgets('ClampingScrollPhysics allows swipe gestures', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.physics, isA<ClampingScrollPhysics>());
    });
  });
}
