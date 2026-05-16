// Spec-walker PoC — feasibility 검증
//
// 목표:
//   1. Patrol on emulator 에서 Riverpod mock 주입이 동작하는가
//   2. 실제 단말 렌더링으로 빈 상태 화면을 캡처할 수 있는가
//   3. assertion (UI element 존재 검증) + 시각 캡처를 한 테스트에서 동시 수행 가능한가
//
// 검증되면:
//   - 기존 alchemist 골든 테스트 폐기 가능 (실폰트, 실디바이스 viewport 이점)
//   - minglit-worker-runtime 의 runtime-qa-explore-* 워커 deprecation 가능
//   - spec-walk = 단순 `patrol test` 결과물
//
// 실행:
//   cd apps/app_user
//   patrol test --flavor dev \
//     --dart-define-from-file=../../minglit_env/dev/flutter.env \
//     --target patrol_test/spec_walker/discovery/user_home_empty_test.dart

import 'package:app_user/src/features/home/home_page.dart';
import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:patrol/patrol.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Mock providers — alchemist 패턴 (test/alchemist/golden_test_helpers.dart) 재사용
// ---------------------------------------------------------------------------

class _MockHomeCoordinator extends Mock implements HomeCoordinator {}

/// Location / eligibility 필터를 비활성화한 ActiveFilters override.
class _NoFiltersNotifier extends ActiveFilters {
  @override
  ExploreFilters build() => const ExploreFilters();
}

/// 추천 피드를 항상 빈 상태로 만드는 override.
class _EmptyRecommendationFeedNotifier extends RecommendationFeedNotifier {
  @override
  RecommendationFeedState build() => const RecommendationFeedState(
        events: [],
        hasMore: false,
      );
}

// ---------------------------------------------------------------------------
// Spec-walker app wrapper
//   MinglitApp 전체가 아니라 minimal app (ProviderScope + MaterialApp + page)
//   alchemist 의 GoldenPageWrapper 와 동일 패턴.
//   외부 의존성 (Supabase / Firebase / Sentry init) 우회.
// ---------------------------------------------------------------------------

Widget _buildSpecWalkerApp({
  required Widget page,
  List<Override> additionalOverrides = const [],
}) {
  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((_) => null),
      authStateChangesProvider.overrideWith((_) => const Stream.empty()),
      notificationInitializerProvider.overrideWith((_) {}),
      homeCoordinatorProvider.overrideWithValue(_MockHomeCoordinator()),
      activeFiltersProvider.overrideWith(_NoFiltersNotifier.new),
      recommendationFeedProvider
          .overrideWith(_EmptyRecommendationFeedNotifier.new),
      ...additionalOverrides,
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: MinglitTheme.materialTheme,
      home: page,
    ),
  );
}

// ---------------------------------------------------------------------------
// PoC test
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('ko_KR');
  });

  patrolTest(
    'discovery/user-home-empty — 추천 이벤트 0건일 때 빈 상태 화면',
    ($) async {
      await $.pumpWidgetAndSettle(
        _buildSpecWalkerApp(page: const HomePage()),
      );

      // === Functional assertions ===
      // 화면 구조가 spec 대로 렌더링되는지 검증
      expect(
        $('Minglit'),
        findsOneWidget,
        reason: 'AppBar 의 Minglit 로고가 보여야 함',
      );
      expect(
        $('추천순'),
        findsOneWidget,
        reason: '첫 번째 필터 칩이 표시되어야 함',
      );
      expect(
        $('마감임박'),
        findsOneWidget,
        reason: '두 번째 필터 칩이 표시되어야 함',
      );
      expect(
        $('추천 이벤트가 없습니다'),
        findsOneWidget,
        reason: '빈 상태 안내 메시지가 표시되어야 함',
      );

      // === Visual capture ===
      // Patrol native screenshot — 실 디바이스 status bar / navigation bar 포함
      await $.native
          .takeScreenshot('discovery_user-home-empty_state-1-empty');
    },
  );
}
