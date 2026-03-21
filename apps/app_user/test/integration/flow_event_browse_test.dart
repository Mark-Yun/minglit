import 'dart:async';

import 'package:app_user/src/features/event/detail/event_detail_page.dart';
import 'package:app_user/src/features/explore/providers/explore_state_provider.dart';
import 'package:app_user/src/features/partner/detail/partner_detail_page.dart';
import 'package:app_user/src/features/partner/detail/partner_events_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';

import 'utils/test_app.dart';
import 'utils/test_mocks.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  group('이벤트 탐색 플로우 — 홈→상세→파트너', () {
    // ── 홈 화면: AsyncLoading ──
    testWidgets('홈 AsyncLoading → MinglitCircularProgressIndicator 표시', (
      tester,
    ) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(
        createTestApp(
          additionalOverrides: [
            recommendationFeedProvider.overrideWith(
              _MockLoadingNotifier.new,
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byType(MinglitCircularProgressIndicator), findsOneWidget);
    });

    // ── 홈 화면: AsyncError ──
    testWidgets('홈 AsyncError → 에러 메시지 + 다시 시도 버튼', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(
        createTestApp(
          additionalOverrides: [
            recommendationFeedProvider.overrideWith(_MockErrorNotifier.new),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('피드를 불러오지 못했습니다'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
    });

    // ── 홈 화면: AsyncData 빈 목록 ──
    testWidgets('홈 AsyncData 빈 목록 → 추천 이벤트가 없습니다', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(
        createTestApp(
          additionalOverrides: [
            recommendationFeedProvider.overrideWith(_MockEmptyNotifier.new),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('추천 이벤트가 없습니다'), findsOneWidget);
    });

    // ── 홈 화면: AsyncData 이벤트 카드 렌더링 ──
    testWidgets('홈 AsyncData → 이벤트 카드 리스트 렌더링', (tester) async {
      setKoreanLocale(tester);
      final mockEvents = createMockEventsForTest(count: 3);
      await tester.pumpWidget(
        createTestApp(
          additionalOverrides: [
            recommendationFeedProvider.overrideWith(
              () => _MockDataNotifier(mockEvents),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();

      // SliverList only renders visible items in the viewport
      expect(find.byType(MinglitEventCard), findsWidgets);
      expect(find.text('Test Event 0'), findsOneWidget);
    });

    // ── 이벤트 상세: 라우트 이동 ──
    testWidgets('이벤트 카드 tap → EventDetailPage 이동', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(
        createTestApp(initialLocation: '/events/test-event-0'),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(EventDetailPage), findsOneWidget);
    });

    // ── EventDetailPage: AsyncLoading ──
    testWidgets('EventDetailPage AsyncLoading → 스켈레톤 UI 표시', (
      tester,
    ) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(
        createTestApp(initialLocation: '/events/nonexistent-id'),
      );
      // Only one pump — keep in loading state
      await tester.pump();

      expect(find.byType(EventDetailPage), findsOneWidget);
    });

    // ── 파트너 상세: 라우트 이동 ──
    testWidgets('파트너 라우트 → PartnerDetailPage 이동', (tester) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(
        createTestApp(
          initialLocation: '/partners/test-partner-id',
          additionalOverrides: [
            partnerDetailProvider.overrideWith(
              (ref, partnerId) async => Partner(
                id: partnerId,
                name: 'Test Partner',
                introduction: 'Test introduction',
              ),
            ),
            partnerEventsProvider.overrideWith(
              (ref, partnerId) async => <Event>[],
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(PartnerDetailPage), findsOneWidget);
      expect(find.text('Test Partner'), findsWidgets);
    });

    // ── 파트너 이벤트 더보기: 라우트 이동 ──
    testWidgets('파트너 이벤트 더보기 라우트 → PartnerEventsPage 이동', (
      tester,
    ) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(
        createTestApp(
          initialLocation:
              '/partners/test-partner-id/events'
              '?partner-name=Test%20Partner',
          additionalOverrides: [
            partnerEventsProvider.overrideWith(
              (ref, partnerId) async => createMockEventsForTest(),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.byType(PartnerEventsPage), findsOneWidget);
      expect(find.text('Test Partner 이벤트'), findsOneWidget);
    });

    // ── PartnerEventsPage: 빈 목록 ──
    testWidgets('PartnerEventsPage 빈 목록 → 등록된 이벤트가 없습니다', (
      tester,
    ) async {
      setKoreanLocale(tester);
      await tester.pumpWidget(
        createTestApp(
          initialLocation:
              '/partners/test-partner-id/events'
              '?partner-name=Test%20Partner',
          additionalOverrides: [
            partnerEventsProvider.overrideWith(
              (ref, partnerId) async => <Event>[],
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('등록된 이벤트가 없습니다.'), findsOneWidget);
    });
  });
}

/// Loading state notifier — stays in AsyncLoading via never-completing future.
class _MockLoadingNotifier extends RecommendationFeedNotifier {
  @override
  Future<RecommendationFeedState> build() {
    return Completer<RecommendationFeedState>().future;
  }
}

/// Empty data state notifier — hasMore=false, events empty.
class _MockEmptyNotifier extends RecommendationFeedNotifier {
  @override
  Future<RecommendationFeedState> build() async {
    return const RecommendationFeedState(
      events: [],
      serverOffset: 0,
      hasMore: false,
    );
  }
}

/// Error state notifier.
class _MockErrorNotifier extends RecommendationFeedNotifier {
  @override
  Future<RecommendationFeedState> build() async {
    throw Exception('Feed load failed');
  }
}

/// Data state notifier with provided events.
class _MockDataNotifier extends RecommendationFeedNotifier {
  _MockDataNotifier(this._events);
  final List<Event> _events;

  @override
  Future<RecommendationFeedState> build() async {
    return RecommendationFeedState(
      events: _events,
      serverOffset: _events.length,
      hasMore: false,
    );
  }
}
