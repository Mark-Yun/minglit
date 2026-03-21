import 'package:app_partner/src/features/party/event/create/event_create_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

Party _makeParty() {
  final now = DateTime.now();
  return Party(
    id: 'party-1',
    partnerId: 'partner-1',
    title: 'Test Party',
    createdAt: now,
    updatedAt: now,
  );
}

Location _makeLocation() {
  final now = DateTime.now();
  return Location(
    id: 'loc-1',
    partnerId: 'partner-1',
    name: 'Test Venue',
    address: '서울시 강남구',
    createdAt: now,
    updatedAt: now,
  );
}

Widget _testApp({
  required WidgetBuilder builder,
  required _TrackingObserver observer,
}) {
  return ProviderScope(
    child: MaterialApp(
      navigatorObservers: [observer],
      home: Builder(
        builder: (context) {
          return Scaffold(body: Builder(builder: builder));
        },
      ),
    ),
  );
}

void main() {
  group('EventCreateCoordinator', () {
    test('can be constructed with a BuildContext', () {
      expect(
        () => EventCreateCoordinator(_FakeBuildContext()),
        returnsNormally,
      );
    });

    testWidgets('openBasicInfoEdit pushes a route', (tester) async {
      var routePushed = false;
      final observer = _TrackingObserver(onPush: () => routePushed = true);

      await tester.pumpWidget(
        _testApp(
          observer: observer,
          builder: (context) => ElevatedButton(
            onPressed: () {
              EventCreateCoordinator(context).openBasicInfoEdit(
                party: _makeParty(),
                onSave: (_, __, ___, ____, _____) {},
              );
            },
            child: const Text('Go'),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pump();

      expect(routePushed, isTrue);
      // Consume render errors from the destination screen (not under test)
      tester.takeException();
    });

    testWidgets('openCapacityContactEdit pushes a route', (tester) async {
      var routePushed = false;
      final observer = _TrackingObserver(onPush: () => routePushed = true);

      await tester.pumpWidget(
        _testApp(
          observer: observer,
          builder: (context) => ElevatedButton(
            onPressed: () {
              EventCreateCoordinator(context).openCapacityContactEdit(
                party: _makeParty(),
                onSave: (_, __, ___) {},
              );
            },
            child: const Text('Go'),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pump();

      expect(routePushed, isTrue);
      tester.takeException();
    });

    testWidgets('openLocationEdit pushes a route', (tester) async {
      var routePushed = false;
      final observer = _TrackingObserver(onPush: () => routePushed = true);

      await tester.pumpWidget(
        _testApp(
          observer: observer,
          builder: (context) => ElevatedButton(
            onPressed: () {
              EventCreateCoordinator(context).openLocationEdit(
                initialLocation: _makeLocation(),
                initialAddressDetail: '3층',
                initialDirectionsGuide: '엘리베이터 이용',
                onSave: (_, __, ___) {},
              );
            },
            child: const Text('Go'),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pump();

      expect(routePushed, isTrue);
      tester.takeException();
    });

    testWidgets('openLocationEdit works with null initial values',
        (tester) async {
      var routePushed = false;
      final observer = _TrackingObserver(onPush: () => routePushed = true);

      await tester.pumpWidget(
        _testApp(
          observer: observer,
          builder: (context) => ElevatedButton(
            onPressed: () {
              EventCreateCoordinator(context).openLocationEdit(
                initialLocation: null,
                initialAddressDetail: null,
                initialDirectionsGuide: null,
                onSave: (_, __, ___) {},
              );
            },
            child: const Text('Go'),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pump();

      expect(routePushed, isTrue);
      tester.takeException();
    });

    testWidgets('openTicketTemplateManage pushes a route', (tester) async {
      var routePushed = false;
      final observer = _TrackingObserver(onPush: () => routePushed = true);

      await tester.pumpWidget(
        _testApp(
          observer: observer,
          builder: (context) => ElevatedButton(
            onPressed: () {
              EventCreateCoordinator(context)
                  .openTicketTemplateManage('party-1');
            },
            child: const Text('Go'),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pump();

      expect(routePushed, isTrue);
      tester.takeException();
    });
  });
}

class _FakeBuildContext extends Fake implements BuildContext {}

class _TrackingObserver extends NavigatorObserver {
  _TrackingObserver({required this.onPush});

  final VoidCallback onPush;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      onPush();
    }
  }
}
