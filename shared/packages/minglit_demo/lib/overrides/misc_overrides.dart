/// Demo overrides for the misc domain:
/// verification, notification, policy, matching, kakao_location.
///
/// Owned by **P1-5 agent**.
///
/// Each fake repository extends the real Supabase implementation, passing
/// [PoisonSupabaseClient] to the parent constructor. Read-path methods used
/// by the demo UI are overridden to serve in-memory fixtures. Any
/// un-overridden method will reach [PoisonSupabaseClient] and throw a loud
/// [StateError] — this is the intended design (see poison_supabase_client.dart).
library;

// ignore: implementation_imports
import 'package:riverpod/src/internals.dart' show Override;
import 'package:minglit_kit/minglit_data.dart';
import 'package:minglit_kit/minglit_logic.dart';

import '../fixtures/demo_misc.dart';
import '../fixtures/demo_world.dart';
import 'poison_supabase_client.dart';

// ── VerificationRepository ─────────────────────────────────────────────────

class _DemoVerificationRepository extends SupabaseVerificationRepository {
  _DemoVerificationRepository()
    : super(supabase: const PoisonSupabaseClient());

  @override
  Future<List<Verification>> getGlobalVerifications() async {
    return const [];
  }

  @override
  Future<List<Verification>> getPartnerVerifications(
    String partnerId, {
    bool isActive = true,
  }) async {
    return const [];
  }

  @override
  Future<Verification?> getVerificationById(String id) async => null;

  @override
  Future<List<Verification>> getVerificationsByIds(List<String> ids) async {
    return const [];
  }

  @override
  Future<List<VerificationRequirementStatus>>
  getPartnerRequirementsStatus({
    required String partnerId,
    required List<String> requiredVerificationIds,
  }) async {
    return const [];
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingRequests(
    String partnerId,
  ) async {
    return const [];
  }

  @override
  Future<List<Map<String, dynamic>>> getRequestsByStatus(
    VerificationStatus status,
  ) async {
    return const [];
  }

  @override
  Future<List<Map<String, dynamic>>> getVerificationComments(
    String submissionId,
  ) async {
    return const [];
  }

  @override
  Future<String> getVerificationProofSignedUrl(String path) async {
    // Return a picsum placeholder so verification proof images render.
    return 'https://picsum.photos/seed/${path.hashCode}/400/300';
  }

  @override
  Future<Map<String, dynamic>?> getSubmissionByApplicationId(
    String applicationId,
  ) async {
    final submission = demoVerifications
        .where((s) => s.applicationId == applicationId)
        .firstOrNull;
    if (submission == null) return null;
    return {
      'id': submission.id,
      'status': submission.status.name,
      'application_id': applicationId,
    };
  }
}

// ── NotificationRepository ─────────────────────────────────────────────────

class _DemoNotificationRepository extends NotificationRepository {
  _DemoNotificationRepository() : super(const PoisonSupabaseClient());

  @override
  Future<List<Map<String, dynamic>>> getNotifications({
    int limit = 20,
    int offset = 0,
  }) async {
    final all = demoNotifications;
    final end = (offset + limit).clamp(0, all.length);
    if (offset >= all.length) return const [];
    return all.sublist(offset, end);
  }

  @override
  Future<UserSettings?> getSettings(String userId) async {
    return UserSettings(
      userId: DemoWorld.userId,
      updatedAt: DemoWorld.offset(const Duration(days: -30)),
      marketingConsent: false,
      serviceNotification: true,
    );
  }

  // Write-path operations are no-ops in demo (no network, no state persistence).
  @override
  Future<void> upsertToken({
    required String userId,
    required String token,
    required String deviceType,
  }) async {}

  @override
  Future<void> deleteToken(String token) async {}

  @override
  Future<void> markAsRead(String notificationId) async {}

  @override
  Future<void> markAllAsRead(String userId) async {}

  @override
  Future<void> deleteNotification(String notificationId) async {}

  @override
  Future<UserSettings?> updateSettings(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    return UserSettings(
      userId: DemoWorld.userId,
      updatedAt: DemoWorld.now,
      marketingConsent: (updates['marketing_consent'] as bool?) ?? false,
      serviceNotification:
          (updates['service_notification'] as bool?) ?? true,
    );
  }
}

// ── PolicyRepository ────────────────────────────────────────────────────────

class _DemoPolicyRepository extends PolicyRepository {
  const _DemoPolicyRepository() : super(const PoisonSupabaseClient());

  @override
  Future<Map<String, dynamic>?> getRefundPolicy() async => demoRefundPolicy;
}

// ── MatchingRepository ──────────────────────────────────────────────────────

class _DemoMatchingRepository extends MatchingRepository {
  _DemoMatchingRepository() : super(supabase: const PoisonSupabaseClient());

  @override
  Future<List<MatchRule>> getMatchRules(String eventId) async {
    return const [];
  }

  @override
  Future<List<MatchPair>> getMyMatches(String eventId) async {
    return demoMatchings
        .where((m) => m.eventId == eventId)
        .toList();
  }

  @override
  Future<int> getMyVoteCount(String eventId) async => 0;

  @override
  Future<Set<String>> getMyVotedCandidateIds(String eventId) async =>
      const {};

  @override
  Future<List<UserProfile>> getMatchingCandidates(String eventId) async =>
      const [];

  // Write-path operations are no-ops in demo mode.
  @override
  Future<void> updateMatchRules({
    required String eventId,
    required List<Map<String, dynamic>> rules,
  }) async {}

  @override
  Future<void> clearMatchRules({required String eventId}) async {}

  @override
  Future<void> castVote({
    required String eventId,
    required String candidateId,
  }) async {}

  @override
  Future<void> commitMatchLikes({
    required String eventId,
    required List<String> candidateIds,
  }) async {}
}

// ── KakaoLocationRepository ─────────────────────────────────────────────────

class _DemoKakaoLocationRepository extends KakaoLocationRepository {
  /// Returns a short list of Seoul landmarks as demo search results.
  @override
  Future<List<Location>> searchKeyword(String query) async {
    if (query.isEmpty) return const [];
    // Return deterministic Seoul location stubs — no Kakao API key needed.
    return [
      Location(
        id: '00000000-0000-4000-8000-E00000000001',
        partnerId: '',
        name: '강남구청',
        address: '서울특별시 강남구 학동로 426',
        region1: '서울',
        region2: '강남구',
        region3: '학동',
        latitude: 37.5172,
        longitude: 127.0473,
        createdAt: DemoWorld.now,
        updatedAt: DemoWorld.now,
      ),
      Location(
        id: '00000000-0000-4000-8000-E00000000002',
        partnerId: '',
        name: '홍대입구역',
        address: '서울특별시 마포구 양화로 지하 160',
        region1: '서울',
        region2: '마포구',
        region3: '서교동',
        latitude: 37.5573,
        longitude: 126.9247,
        createdAt: DemoWorld.now,
        updatedAt: DemoWorld.now,
      ),
    ];
  }
}

// ── Provider override list ──────────────────────────────────────────────────

List<Override> miscDomainOverrides() => [
  verificationRepositoryProvider.overrideWith(
    (_) => _DemoVerificationRepository(),
  ),
  notificationRepositoryProvider.overrideWith(
    (_) => _DemoNotificationRepository(),
  ),
  policyRepositoryProvider.overrideWith((_) => const _DemoPolicyRepository()),
  matchingRepositoryProvider.overrideWith((_) => _DemoMatchingRepository()),
  kakaoLocationRepositoryProvider.overrideWith(
    (_) => _DemoKakaoLocationRepository(),
  ),
];
