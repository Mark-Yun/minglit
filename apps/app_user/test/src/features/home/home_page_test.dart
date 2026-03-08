import 'package:app_user/src/features/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  late MockEventRepository mockEventRepository;

  setUp(() {
    mockEventRepository = MockEventRepository();

    // Return empty lists for all feed types by default
    for (final type in EventFeedType.values) {
      when(
        () => mockEventRepository.getEventsByType(
          type: type,
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => []);
    }
  });

  Widget createTestWidget({List<dynamic> overrides = const []}) {
    return ProviderScope(
      overrides: [
        eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ...overrides.cast(),
      ],
      child: MaterialApp(
        theme: MinglitTheme.materialTheme,
        home: const HomePage(),
      ),
    );
  }

  group('HomePage', () {
    testWidgets('renders notification bell icon', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('renders all 4 category chips', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('내 주변'), findsOneWidget);
      expect(find.text('신규 오픈'), findsWidgets); // chip + section header
      expect(find.text('마감 임박'), findsWidgets);
      expect(find.text('얼리버드'), findsOneWidget);
    });

    testWidgets('renders 3 event feed section headers', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Section headers use type.title
      expect(find.text('신규 오픈'), findsWidgets);
      expect(find.text('마감 임박'), findsWidgets);
      expect(find.text('얼리버드 특가'), findsWidgets);
    });

    testWidgets('renders 더보기 buttons for each section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('더보기'), findsNWidgets(3));
    });

    testWidgets('shows empty state when no events', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Each section shows empty message
      expect(find.textContaining('없습니다'), findsNWidgets(3));
    });

    testWidgets('renders event cards when data is available', (tester) async {
      final testEvents = [
        Event(
          id: 'event1',
          partyId: 'party1',
          startTime: DateTime.now().add(const Duration(days: 3)),
          endTime: DateTime.now().add(const Duration(days: 3, hours: 2)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          title: 'Test Party Event',
          tickets: [
            Ticket(
              id: 't1',
              name: 'General',
              price: 15000,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
        ),
      ];

      when(
        () => mockEventRepository.getEventsByType(
          type: EventFeedType.newArrivals,
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => testEvents);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Test Party Event'), findsOneWidget);
    });
  });
}
