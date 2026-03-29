import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_bottom_cta.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(bottomNavigationBar: child),
    );
  }

  group('MinglitBottomCTA', () {
    group('single variant', () {
      testWidgets('renders primary button with label', (tester) async {
        await tester.pumpWidget(
          wrap(MinglitBottomCTA(label: '참가 신청하기', onPressed: () {})),
        );

        expect(find.text('참가 신청하기'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('renders button with icon', (tester) async {
        await tester.pumpWidget(
          wrap(
            MinglitBottomCTA(
              label: '다음',
              onPressed: () {},
              icon: Icons.arrow_forward,
            ),
          ),
        );

        expect(find.text('다음'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      });

      testWidgets('calls onPressed when tapped', (tester) async {
        var tapped = false;
        await tester.pumpWidget(
          wrap(MinglitBottomCTA(label: '확인', onPressed: () => tapped = true)),
        );

        await tester.tap(find.byType(ElevatedButton));
        expect(tapped, isTrue);
      });

      testWidgets('disables button when enabled is false', (tester) async {
        var tapped = false;
        await tester.pumpWidget(
          wrap(
            MinglitBottomCTA(
              label: '확인',
              onPressed: () => tapped = true,
              enabled: false,
            ),
          ),
        );

        await tester.tap(find.byType(ElevatedButton));
        expect(tapped, isFalse);
      });
    });

    group('dual variant', () {
      testWidgets('renders two buttons', (tester) async {
        await tester.pumpWidget(
          wrap(
            MinglitBottomCTA.dual(
              label: '참가 신청',
              onPressed: () {},
              secondaryLabel: '취소',
              onSecondaryPressed: () {},
            ),
          ),
        );

        expect(find.text('참가 신청'), findsOneWidget);
        expect(find.text('취소'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
        expect(find.byType(OutlinedButton), findsOneWidget);
      });

      testWidgets('calls correct callbacks', (tester) async {
        var primaryTapped = false;
        var secondaryTapped = false;

        await tester.pumpWidget(
          wrap(
            MinglitBottomCTA.dual(
              label: '확인',
              onPressed: () => primaryTapped = true,
              secondaryLabel: '취소',
              onSecondaryPressed: () => secondaryTapped = true,
            ),
          ),
        );

        await tester.tap(find.byType(ElevatedButton));
        expect(primaryTapped, isTrue);

        await tester.tap(find.byType(OutlinedButton));
        expect(secondaryTapped, isTrue);
      });
    });

    group('withPrice variant', () {
      testWidgets('renders price text and button', (tester) async {
        await tester.pumpWidget(
          wrap(
            MinglitBottomCTA.withPrice(
              label: '참가 신청하기',
              onPressed: () {},
              priceText: '20,000원~',
              priceSubText: '최저가',
            ),
          ),
        );

        expect(find.text('20,000원~'), findsOneWidget);
        expect(find.text('최저가'), findsOneWidget);
        expect(find.text('참가 신청하기'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('renders without priceSubText', (tester) async {
        await tester.pumpWidget(
          wrap(
            MinglitBottomCTA.withPrice(
              label: '결제하기',
              onPressed: () {},
              priceText: '30,000원',
            ),
          ),
        );

        expect(find.text('30,000원'), findsOneWidget);
        expect(find.text('결제하기'), findsOneWidget);
      });
    });

    group('SafeArea', () {
      testWidgets('wraps content in SafeArea', (tester) async {
        await tester.pumpWidget(
          wrap(MinglitBottomCTA(label: '확인', onPressed: () {})),
        );

        final ctaFinder = find.byType(MinglitBottomCTA);
        expect(
          find.descendant(of: ctaFinder, matching: find.byType(SafeArea)),
          findsOneWidget,
        );
      });
    });

    group('keyboard visibility', () {
      testWidgets('hides when keyboard is visible', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                viewInsets: EdgeInsets.only(bottom: 300),
              ),
              child: Scaffold(
                bottomNavigationBar: MinglitBottomCTA(
                  label: '확인',
                  onPressed: () {},
                ),
              ),
            ),
          ),
        );

        expect(find.text('확인'), findsNothing);
        // Fix #629: SizedBox.shrink 반환 확인 — 키보드 표시 시 CTA가 숨겨짐
        final shrinkFinder = find.byWidgetPredicate(
          (widget) =>
              widget is SizedBox && widget.width == 0 && widget.height == 0,
        );
        expect(shrinkFinder, findsOneWidget);
      });
    });
  });
}
