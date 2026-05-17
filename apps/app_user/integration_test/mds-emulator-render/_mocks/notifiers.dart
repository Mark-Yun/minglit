// 화면 builder 들이 공통으로 쓰는 Notifier override.

import 'dart:async';

import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:minglit_kit/minglit_kit.dart';

// ── Auth ─────────────────────────────────────────────────────────────────────

/// 인증 대기 (idle) 상태 — 로그인 폼 표시.
class IdleAuthController extends AuthController {
  @override
  FutureOr<void> build() {}
}

// ── Search ───────────────────────────────────────────────────────────────────

/// 검색 쿼리를 특정 값으로 고정 (initState의 clear() 무시).
class LockedSearchQueryNotifier extends SearchQuery {
  LockedSearchQueryNotifier(this._query);

  final String _query;

  @override
  String build() => _query;

  @override
  void update(String query) {} // 잠금 — 외부 변경 무시

  @override
  void clear() {} // 잠금 — SearchPage.initState clear() 무시
}

// ── Notification List ────────────────────────────────────────────────────────

/// 빈 알림 목록.
class EmptyNotificationListNotifier extends NotificationList {
  @override
  Future<List<Map<String, dynamic>>> build() async => [];
}

/// 정적 알림 목록 (2건).
class StaticNotificationListNotifier extends NotificationList {
  @override
  Future<List<Map<String, dynamic>>> build() async => [
    {
      'id': 'notif-1',
      'title': '이벤트 예약 확정',
      'body': '5월 20일 파티 예약이 확정되었습니다.',
      'is_read': false,
      'created_at': '2026-05-17T10:00:00.000Z',
      'deep_link': null,
    },
    {
      'id': 'notif-2',
      'title': '새 이벤트 추천',
      'body': '관심사에 맞는 새 이벤트가 등록되었습니다.',
      'is_read': true,
      'created_at': '2026-05-16T14:30:00.000Z',
      'deep_link': null,
    },
  ];
}

// ── Notification Settings ─────────────────────────────────────────────────────

/// 알림 설정 로드 완료 (service ON, marketing OFF).
class LoadedNotificationSettingsNotifier
    extends NotificationSettingsController {
  @override
  FutureOr<UserSettings?> build() async => UserSettings(
    userId: 'mock-user-1',
    updatedAt: DateTime.utc(2026, 5, 17),
    serviceNotification: true,
    marketingConsent: false,
  );
}

// ── Consent ──────────────────────────────────────────────────────────────────

/// 동의 정보 로드 실패 상태.
class ErrorConsentController extends ConsentController {
  @override
  FutureOr<List<UserConsent>> build() => throw Exception('Failed to load consents');
}

/// 필터 (location, eligibility) 비활성화.
class NoFiltersNotifier extends ActiveFilters {
  @override
  ExploreFilters build() => const ExploreFilters();
}

/// 빈 추천 피드.
class EmptyRecommendationFeedNotifier extends RecommendationFeedNotifier {
  @override
  Future<RecommendationFeedState> build() async =>
      const RecommendationFeedState(
        events: [],
        serverOffset: 0,
        hasMore: false,
      );
}

/// 지정한 event 목록을 가진 추천 피드.
class StaticRecommendationFeedNotifier extends RecommendationFeedNotifier {
  StaticRecommendationFeedNotifier(this._events);

  final List<Event> _events;

  @override
  Future<RecommendationFeedState> build() async => RecommendationFeedState(
    events: _events,
    serverOffset: _events.length,
    hasMore: false,
  );
}
