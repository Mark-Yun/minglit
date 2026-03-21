import 'package:app_partner/src/features/party/create/party_create_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PartyCreateCoordinator', () {
    testWidgets('onPartyCreated pops the navigator', (tester) async {
      var popped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (innerContext) {
                          return Scaffold(
                            body: ElevatedButton(
                              onPressed: () {
                                final coordinator = PartyCreateCoordinator(
                                  innerContext,
                                );
                                coordinator.onPartyCreated();
                                popped = true;
                              },
                              child: const Text('pop'),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  child: const Text('push'),
                ),
              );
            },
          ),
        ),
      );

      // Push a second route
      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();

      // Pop it via coordinator
      await tester.tap(find.text('pop'));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
      // We should be back on the first page
      expect(find.text('push'), findsOneWidget);
    });

    testWidgets('onError handles error without crashing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    final coordinator = PartyCreateCoordinator(context);
                    coordinator.onError(
                      Exception('test error'),
                      StackTrace.current,
                    );
                  },
                  child: const Text('error'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('error'));
      await tester.pumpAndSettle();

      // Should not throw — error is handled gracefully
    });
  });
}
