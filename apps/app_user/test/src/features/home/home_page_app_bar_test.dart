import 'package:app_user/src/logic/feed_state_provider.dart';
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
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => []);
    }
  });

  Widget createTestWidget({List<dynamic> overrides = const []}) {
    return ProviderScope(
      overrides: [
        eventRepositoryProvider.overrideWithValue(mockEventRepository),
        // Disable active filters to avoid triggering location services
        activeFiltersProvider.overrideWith(_NoFiltersNotifier.new),
        ...overrides.cast(),
      ],
      child: MaterialApp(
        theme: MinglitTheme.materialTheme,
        home: const HomePage(),
      ),
    );
  }

  group('HomePage AppBar - Auth-aware widgets', () {
    group('when user is not logged in', () {
      testWidgets('renders search icon', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            overrides: [currentUserProvider.overrideWith((_) => null)],
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.search), findsOneWidget);
      });

      testWidgets('does not render notification bell icon', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            overrides: [currentUserProvider.overrideWith((_) => null)],
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.notifications_outlined), findsNothing);
      });

      testWidgets('renders profile icon (person_outline)', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            overrides: [currentUserProvider.overrideWith((_) => null)],
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.person_outline), findsOneWidget);
      });

      testWidgets('does not render CircleAvatar in app bar', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            overrides: [currentUserProvider.overrideWith((_) => null)],
          ),
        );
        await tester.pump();

        expect(find.byType(CircleAvatar), findsNothing);
      });
    });

    group('when user is logged in with avatar', () {
      testWidgets('renders search icon', (tester) async {
        final mockUser = _createMockUser(
          id: 'user123',
          email: 'test@example.com',
          avatarUrl: 'https://example.com/avatar.jpg',
        );

        await tester.pumpWidget(
          createTestWidget(
            overrides: [currentUserProvider.overrideWith((_) => mockUser)],
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.search), findsOneWidget);
      });

      testWidgets('renders notification bell icon', (tester) async {
        final mockUser = _createMockUser(
          id: 'user123',
          email: 'test@example.com',
          avatarUrl: 'https://example.com/avatar.jpg',
        );

        await tester.pumpWidget(
          createTestWidget(
            overrides: [currentUserProvider.overrideWith((_) => mockUser)],
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      });

      testWidgets('does not render profile icon (person_outline)', (
        tester,
      ) async {
        final mockUser = _createMockUser(
          id: 'user123',
          email: 'test@example.com',
          avatarUrl: 'https://example.com/avatar.jpg',
        );

        await tester.pumpWidget(
          createTestWidget(
            overrides: [currentUserProvider.overrideWith((_) => mockUser)],
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.person_outline), findsNothing);
      });

      testWidgets('renders CircleAvatar in app bar', (tester) async {
        final mockUser = _createMockUser(
          id: 'user123',
          email: 'test@example.com',
          avatarUrl: 'https://example.com/avatar.jpg',
        );

        await tester.pumpWidget(
          createTestWidget(
            overrides: [currentUserProvider.overrideWith((_) => mockUser)],
          ),
        );
        await tester.pump();

        expect(find.byType(CircleAvatar), findsOneWidget);
      });
    });

    group('when user is logged in without avatar', () {
      testWidgets('renders CircleAvatar with fallback icon', (tester) async {
        final mockUser = _createMockUser(
          id: 'user123',
          email: 'test@example.com',
        );

        await tester.pumpWidget(
          createTestWidget(
            overrides: [currentUserProvider.overrideWith((_) => mockUser)],
          ),
        );
        await tester.pump();

        expect(find.byType(CircleAvatar), findsOneWidget);
      });

      testWidgets('renders notification bell icon', (tester) async {
        final mockUser = _createMockUser(
          id: 'user123',
          email: 'test@example.com',
        );

        await tester.pumpWidget(
          createTestWidget(
            overrides: [currentUserProvider.overrideWith((_) => mockUser)],
          ),
        );
        await tester.pump();

        expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      });
    });

    group('NavigationBar removal', () {
      testWidgets('does not render NavigationBar', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            overrides: [currentUserProvider.overrideWith((_) => null)],
          ),
        );
        await tester.pump();

        expect(find.byType(NavigationBar), findsNothing);
      });
    });
  });
}

/// A notifier that starts with no active filters (all disabled),
/// so filteredEventsProvider passes through without triggering
/// location services or eligibility checks.
class _NoFiltersNotifier extends ActiveFilters {
  @override
  ExploreFilters build() => const ExploreFilters();
}

/// Helper function to create a mock User with userMetadata
User _createMockUser({
  required String id,
  required String email,
  String? avatarUrl,
}) {
  final mockUser = MockUser();

  when(() => mockUser.id).thenReturn(id);
  when(() => mockUser.email).thenReturn(email);

  final metadata = <String, dynamic>{
    'full_name': 'Test User',
  };
  if (avatarUrl != null) {
    metadata['avatar_url'] = avatarUrl;
  }

  when(() => mockUser.userMetadata).thenReturn(metadata);

  return mockUser;
}
