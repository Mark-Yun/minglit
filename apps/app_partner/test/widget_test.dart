// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  testWidgets('Partner login screen renders', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MinglitLoginScreen(isPartner: true),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Google로 시작하기'), findsOneWidget);
    expect(find.text('Kakao로 시작하기'), findsOneWidget);
  });

  testWidgets('Partner login screen shows PARTNER label', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MinglitLoginScreen(isPartner: true),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('PARTNER'), findsOneWidget);
  });

  testWidgets('Partner login screen shows partner slogan', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MinglitLoginScreen(isPartner: true),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Verified Vibe, Spark Your Business'), findsOneWidget);
  });

  testWidgets('Partner login screen shows partner inquiry button', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MinglitLoginScreen(isPartner: true),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('파트너 입점 문의'), findsOneWidget);
  });

  testWidgets('User login screen does not show PARTNER label', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MinglitLoginScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('PARTNER'), findsNothing);
  });

  testWidgets('User login screen shows user slogan', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MinglitLoginScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Verified Vibe, Spark Your Moment'), findsOneWidget);
  });

  testWidgets('Apple sign-in button renders when callback provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MinglitLoginScreen(
            isPartner: true,
            onAppleSignIn: () {},
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Apple로 시작하기'), findsOneWidget);
  });

  testWidgets('Apple sign-in button hidden when no callback', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MinglitLoginScreen(isPartner: true),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Apple로 시작하기'), findsNothing);
  });
}
