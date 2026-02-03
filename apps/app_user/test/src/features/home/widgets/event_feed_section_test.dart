import 'package:app_user/src/features/home/widgets/event_feed_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../utils/mocks.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  late MockEventRepository mockEventRepository;

  setUp(() {
    mockEventRepository = MockEventRepository();
  });

  Widget createTestWidget({
    EventFeedType type = EventFeedType.newArrivals,
    List<dynamic> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ...overrides.cast(),
      ],
      child: MaterialApp(
        theme: MinglitTheme.materialTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            child: EventFeedSection(type: type),
          ),
        ),
      ),
    );
  }

  group('EventFeedSection', () {
    testWidgets('renders section title from EventFeedType', (tester) async {
      when(
        () => mockEventRepository.getEventsByType(
          type: EventFeedType.newArrivals,
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('신규 오픈'), findsOneWidget);
    });

    testWidgets('renders 더보기 button', (tester) async {
      when(
        () => mockEventRepository.getEventsByType(
          type: EventFeedType.closingSoon,
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(
        createTestWidget(type: EventFeedType.closingSoon),
      );
      await tester.pump();

      expect(find.text('더보기'), findsOneWidget);
    });

    testWidgets('shows empty message when no events', (tester) async {
      when(
        () => mockEventRepository.getEventsByType(
          type: EventFeedType.newArrivals,
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('현재 신규 오픈이 없습니다.'), findsOneWidget);
    });

    testWidgets('renders event cards when data available', (tester) async {
      final testEvents = [
        Event(
          id: 'e1',
          partyId: 'p1',
          startTime: DateTime.now().add(const Duration(days: 5)),
          endTime: DateTime.now().add(const Duration(days: 5, hours: 2)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          title: 'Amazing Party',
          tickets: [
            Ticket(
              id: 't1',
              name: 'VIP',
              price: 30000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
        ),
        Event(
          id: 'e2',
          partyId: 'p2',
          startTime: DateTime.now().add(const Duration(days: 7)),
          endTime: DateTime.now().add(const Duration(days: 7, hours: 3)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          title: 'Cool Gathering',
          tickets: [
            Ticket(
              id: 't2',
              name: 'Standard',
              price: 10000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
        ),
      ];

      when(
        () => mockEventRepository.getEventsByType(
          type: EventFeedType.earlyBird,
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(
        createTestWidget(type: EventFeedType.earlyBird),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Amazing Party'), findsOneWidget);
      expect(find.text('Cool Gathering'), findsOneWidget);
      expect(find.byType(MinglitEventCard), findsNWidgets(2));
    });

    testWidgets('uses horizontal scroll direction', (tester) async {
      when(
        () => mockEventRepository.getEventsByType(
          type: EventFeedType.newArrivals,
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => [
          Event(
            id: 'e1',
            partyId: 'p1',
            startTime: DateTime.now().add(const Duration(days: 1)),
            endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            title: 'Scroll Test',
            tickets: [
              Ticket(
                id: 't1',
                name: 'A',
                price: 5000,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump();

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.scrollDirection, Axis.horizontal);
    });
  });
}
