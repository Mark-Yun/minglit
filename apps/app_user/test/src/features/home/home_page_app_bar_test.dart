import 'package:app_user/src/features/home/home_page.dart';
import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:app_user/src/routing/app_router.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../utils/mocks.dart';

class MockGoRouter extends Mock implements GoRouter {}

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

      // Fix #1633: GUEST 프로필 탭 시 from=/my 전달 (기존 from=/ 버그 회귀 방지)
      testWidgets('tapping profile icon navigates to login with from=/my', (
        tester,
      ) async {
        final mockRouter = MockGoRouter();
        when(
          () => mockRouter.go(any(), extra: any(named: 'extra')),
        ).thenReturn(null);

        await tester.pumpWidget(
          createTestWidget(
            overrides: [
              currentUserProvider.overrideWith((_) => null),
              goRouterProvider.overrideWithValue(mockRouter),
            ],
          ),
        );
        await tester.pump();

        await tester.tap(find.byIcon(Icons.person_outline));
        await tester.pump();

        // Verify login route with from=/my: LoginRoute(from: '/my').location
        // generates '/login?from=%2Fmy'. Parse the URL to assert path + param.
        final captured = verify(
          () => mockRouter.go(
            captureAny(that: isA<String>()),
            extra: any(named: 'extra'),
          ),
        ).captured;

        final uri = Uri.parse(captured.single as String);
        expect(uri.path, '/login');
        expect(uri.queryParameters['from'], '/my');
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

    // Fix #2356: 알림 버튼 — 접근성 라벨 회귀 가드 (NAF="true" 재발 방지)
    group('Notification button tooltip — #2356 regression guard', () {
      testWidgets('로그인 상태: 알림 버튼 tooltip이 존재한다', (tester) async {
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

        expect(find.byTooltip('알림'), findsOneWidget);
      });
    });

    // Fix #2339: 검색 버튼 — 접근성 라벨 + 내비게이션 회귀 가드
    // QA automation이 좌표 대신 시맨틱(tooltip)으로 버튼을 찾을 수 있는지 검증한다.
    group('Search button navigation — #2339 regression guard', () {
      testWidgets('비로그인 상태: 검색 버튼 tooltip이 존재한다', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            overrides: [currentUserProvider.overrideWith((_) => null)],
          ),
        );
        await tester.pump();

        expect(find.byTooltip('검색'), findsOneWidget);
      });

      testWidgets('로그인 상태: 검색 버튼 tooltip이 존재한다', (tester) async {
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

        expect(find.byTooltip('검색'), findsOneWidget);
      });

      testWidgets('비로그인 상태: 검색 버튼 탭 시 /search push', (tester) async {
        final mockRouter = MockGoRouter();
        when(() => mockRouter.push(any())).thenAnswer((_) async => null);
        when(
          () => mockRouter.go(any(), extra: any(named: 'extra')),
        ).thenReturn(null);

        await tester.pumpWidget(
          createTestWidget(
            overrides: [
              currentUserProvider.overrideWith((_) => null),
              goRouterProvider.overrideWithValue(mockRouter),
            ],
          ),
        );
        await tester.pump();

        await tester.tap(find.byTooltip('검색'));
        await tester.pump();

        verify(
          () => mockRouter.push(const SearchRoute().location),
        ).called(1);
      });
    });

    // Fix #2107: 마이페이지 버튼 — 접근성 라벨 + 내비게이션 회귀 가드
    // QA automation이 좌표 대신 시맨틱(tooltip)으로 버튼을 찾을 수 있는지 검증한다.
    group('Profile button navigation — #2107 regression guard', () {
      testWidgets('로그인 상태: 마이페이지 버튼 tooltip이 존재한다', (tester) async {
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

        expect(find.byTooltip('마이페이지'), findsOneWidget);
      });

      testWidgets('비로그인 상태: 마이페이지 버튼 tooltip이 존재한다', (tester) async {
        await tester.pumpWidget(
          createTestWidget(
            overrides: [currentUserProvider.overrideWith((_) => null)],
          ),
        );
        await tester.pump();

        expect(find.byTooltip('마이페이지'), findsOneWidget);
      });

      testWidgets('로그인 상태: 마이페이지 버튼 탭 시 /my push', (tester) async {
        final mockRouter = MockGoRouter();
        when(() => mockRouter.push(any())).thenAnswer((_) async => null);
        when(
          () => mockRouter.go(any(), extra: any(named: 'extra')),
        ).thenReturn(null);

        final mockUser = _createMockUser(
          id: 'user123',
          email: 'test@example.com',
        );

        await tester.pumpWidget(
          createTestWidget(
            overrides: [
              currentUserProvider.overrideWith((_) => mockUser),
              goRouterProvider.overrideWithValue(mockRouter),
            ],
          ),
        );
        await tester.pump();

        await tester.tap(find.byTooltip('마이페이지'));
        await tester.pump();

        verify(
          () => mockRouter.push(const MyPageRoute().location),
        ).called(1);
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
