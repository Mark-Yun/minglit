import 'package:app_user/src/features/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import 'utils/mocks.dart';

void main() {
  testWidgets('App smoke test - HomePage renders', (tester) async {
    final mockEventRepository = MockEventRepository();

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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
        ],
        child: MaterialApp(
          theme: MinglitTheme.materialTheme,
          home: const HomePage(),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(HomePage), findsOneWidget);
  });
}
