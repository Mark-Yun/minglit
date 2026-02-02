import 'package:app_user/src/features/party/party_curation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Party Browse Flow', () {
    testWidgets('Curation screen shows empty state', (tester) async {
      tester.binding.platformDispatcher.localeTestValue = const Locale('ko');
      tester.binding.platformDispatcher.localesTestValue = const [Locale('ko')];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProfileProvider.overrideWith((ref) async => null),
            eventFeedProvider(
              type: EventFeedType.newArrivals,
            ).overrideWith((ref) async => <Event>[]),
          ],
          child: const MaterialApp(
            home: PartyCurationScreen(type: EventFeedType.newArrivals),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('현재 표시할 파티가 없습니다.'), findsOneWidget);
    });
  });
}
