import 'package:app_partner/src/features/party/list/party_list_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PartyListCoordinator', () {
    testWidgets('goToCreate triggers route push', (tester) async {
      late PartyListCoordinator coordinator;
      var pushCount = 0;

      final observer = _CountingObserver(onPushed: () => pushCount++);

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Builder(
            builder: (context) {
              coordinator = PartyListCoordinator(context);
              return const Scaffold(body: Text('test'));
            },
          ),
        ),
      );

      final initialPushCount = pushCount;

      // goToCreate falls back to Navigator.push when GoRouter is unavailable.
      // The pushed page may throw during build (no ProviderScope), which is
      // expected in this unit test scope — we only verify navigation triggers.
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      coordinator.goToCreate();
      await tester.pump();
      FlutterError.onError = originalOnError;

      expect(pushCount, greaterThan(initialPushCount));
    });

    testWidgets('goToDetail triggers route push', (tester) async {
      late PartyListCoordinator coordinator;
      var pushCount = 0;

      final observer = _CountingObserver(onPushed: () => pushCount++);

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Builder(
            builder: (context) {
              coordinator = PartyListCoordinator(context);
              return const Scaffold(body: Text('test'));
            },
          ),
        ),
      );

      final initialPushCount = pushCount;

      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};
      coordinator.goToDetail('party-1');
      await tester.pump();
      FlutterError.onError = originalOnError;

      expect(pushCount, greaterThan(initialPushCount));
    });
  });
}

class _CountingObserver extends NavigatorObserver {
  _CountingObserver({required this.onPushed});

  final VoidCallback onPushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onPushed();
  }
}
