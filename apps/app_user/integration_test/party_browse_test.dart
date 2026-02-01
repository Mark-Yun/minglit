import 'package:app_user/main.dart';
import 'package:app_user/src/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

// ---------------------------------------------------------------------------
// Test Helper (inline to avoid cross-file import issues in integration_test)
// ---------------------------------------------------------------------------

const _supabaseUrl = 'http://127.0.0.1:54321';
const _supabaseAnonKey = 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';

bool _servicesInitialized = false;

Future<void> _initServices() async {
  if (_servicesInitialized) return;
  await initializeDateFormatting('ko_KR');
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  _servicesInitialized = true;
}

Future<Widget> _createApp() async {
  await _initServices();
  return ProviderScope(
    overrides: [
      authConfigProvider.overrideWithValue(
        const AuthConfig(
          webClientId: '',
          defaultRedirectUrl: 'http://localhost:3000',
        ),
      ),
      notificationDeepLinkHandlerProvider.overrideWith((ref) {
        final router = ref.read(goRouterProvider);
        return router.go;
      }),
    ],
    child: const MinglitApp(),
  );
}

Future<void> pumpApp(
  WidgetTester tester, {
  Duration settleTimeout = const Duration(seconds: 10),
}) async {
  final app = await _createApp();
  await tester.pumpWidget(app);
  await tester.pumpAndSettle(settleTimeout);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Party Browse Flow', () {
    testWidgets('App launches without errors', (tester) async {
      await pumpApp(tester);

      // App should load without showing error screen
      expect(find.textContaining('Error:'), findsNothing);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Curation screen shows events or empty state', (
      tester,
    ) async {
      await pumpApp(tester);

      // Navigate to curation (new arrivals)
      final context = tester.element(find.byType(MaterialApp).first);
      GoRouter.of(context).go('/curation');
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Either events are loaded or empty state is shown
      final eventCards = find.byType(MinglitEventCard);

      if (eventCards.evaluate().isEmpty) {
        // No seeded data — verify empty state
        expect(find.text('현재 표시할 파티가 없습니다.'), findsOneWidget);
      } else {
        // Events exist — verify at least one card rendered
        expect(eventCards, findsWidgets);
      }
    });

    testWidgets('Tapping event card opens detail screen', (tester) async {
      await pumpApp(tester);

      // Navigate to curation
      final context = tester.element(find.byType(MaterialApp).first);
      GoRouter.of(context).go('/curation');
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final eventCards = find.byType(MinglitEventCard);

      // Skip if no seeded data available
      if (eventCards.evaluate().isEmpty) return;

      // Tap first event card
      await tester.tap(eventCards.first);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify we're on the detail screen
      expect(find.text('상세 소개'), findsOneWidget);
      expect(find.text('참여 자격'), findsOneWidget);

      // Bottom ticket bar should be visible
      expect(find.text('최저가'), findsOneWidget);

      // For unauthenticated users, button should say "로그인하고 신청하기"
      expect(find.text('로그인하고 신청하기'), findsOneWidget);
    });
  });
}
