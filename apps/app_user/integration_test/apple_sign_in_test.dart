import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Apple Sign-In', () {
    testWidgets('Login screen shows Apple button on supported platforms', (
      tester,
    ) async {
      tester.binding.platformDispatcher.localeTestValue = const Locale('ko');
      tester.binding.platformDispatcher.localesTestValue = const [Locale('ko')];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MinglitLoginScreen(
              onAppleSignIn: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      final isAppleSupported = kIsWeb ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS;

      if (isAppleSupported) {
        expect(find.text('Apple로 시작하기'), findsOneWidget);
      } else {
        expect(find.text('Apple로 시작하기'), findsNothing);
      }
    });
  });
}
