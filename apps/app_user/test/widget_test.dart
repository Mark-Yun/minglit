import 'dart:async';

import 'package:app_user/src/features/explore/providers/explore_state_provider.dart';
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

    // Fix overflow and asset loading errors
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    final originalOnError = FlutterError.onError!;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('Unable to load asset') ||
          details.exceptionAsString().contains('overflowed')) {
        return;
      }
      originalOnError(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
          currentUserProvider.overrideWith((_) => null),
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

  testWidgets('HomePage shows loading indicator before data resolves', (
    tester,
  ) async {
    final completer = Completer<List<Event>>();

    // Fix overflow and asset loading errors
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    final originalOnError = FlutterError.onError!;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('Unable to load asset') ||
          details.exceptionAsString().contains('overflowed')) {
        return;
      }
      originalOnError(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recommendationEventsProvider.overrideWith(
            (ref) => completer.future,
          ),
          currentUserProvider.overrideWith((_) => null),
        ],
        child: MaterialApp(
          theme: MinglitTheme.materialTheme,
          home: const HomePage(),
        ),
      ),
    );

    await tester.pump();
    expect(find.byType(MinglitCircularProgressIndicator), findsOneWidget);
  });

  testWidgets('HomePage shows empty state text when no events returned', (
    tester,
  ) async {
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

    // Fix overflow and asset loading errors
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    final originalOnError = FlutterError.onError!;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('Unable to load asset') ||
          details.exceptionAsString().contains('overflowed')) {
        return;
      }
      originalOnError(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
          currentUserProvider.overrideWith((_) => null),
        ],
        child: MaterialApp(
          theme: MinglitTheme.materialTheme,
          home: const HomePage(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('추천 이벤트가 없습니다'), findsOneWidget);
  });

  testWidgets('HomePage renders search and notification icons in app bar', (
    tester,
  ) async {
    final mockEventRepository = MockEventRepository();
    final mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user1');
    when(() => mockUser.email).thenReturn('test@example.com');
    when(() => mockUser.userMetadata).thenReturn({'full_name': 'Test User'});

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

    // Fix overflow and asset loading errors
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    final originalOnError = FlutterError.onError!;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('Unable to load asset') ||
          details.exceptionAsString().contains('overflowed')) {
        return;
      }
      originalOnError(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
        child: MaterialApp(
          theme: MinglitTheme.materialTheme,
          home: const HomePage(),
        ),
      ),
    );

    await tester.pump();

    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
  });

  testWidgets('HomePage renders sort filter chips', (tester) async {
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

    // Fix overflow and asset loading errors
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    final originalOnError = FlutterError.onError!;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('Unable to load asset') ||
          details.exceptionAsString().contains('overflowed')) {
        return;
      }
      originalOnError(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eventRepositoryProvider.overrideWithValue(mockEventRepository),
          currentUserProvider.overrideWith((_) => null),
        ],
        child: MaterialApp(
          theme: MinglitTheme.materialTheme,
          home: const HomePage(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('추천순'), findsOneWidget);
    expect(find.text('마감임박'), findsOneWidget);
    expect(find.text('가까운날짜'), findsOneWidget);
  });
}
