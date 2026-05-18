/// Demo overrides for the event/party/tag/location domain.
///
/// Wires four fake repositories that serve in-memory fixture data instead of
/// hitting Supabase. Only read-path methods exercised by the demo UI are
/// overridden; every write / mutation method throws via [PoisonSupabaseClient]
/// (loud failure surfaces missing overrides immediately).
library;

// ignore: implementation_imports
import 'package:riverpod/src/internals.dart' show Override;
import 'package:minglit_kit/minglit_data.dart';

import '../fixtures/demo_events.dart';
import '../fixtures/demo_parties.dart';
import '../fixtures/demo_world.dart';
import 'poison_supabase_client.dart';

// ── EventRepository ─────────────────────────────────────────────────────────

class _DemoEventRepository extends EventRepository {
  _DemoEventRepository() : super(supabase: const PoisonSupabaseClient());

  // ── Feed queries ─────────────────────────────────────────────────────────

  @override
  Future<List<Event>> getEventsByType({
    required EventFeedType type,
    double? latitude,
    double? longitude,
    int limit = 10,
    Set<String>? blockedPartnerIds,
    int offset = 0,
  }) async {
    final active = demoEvents
        .where(
          (e) =>
              e.status == 'scheduled' ||
              e.status == 'active' ||
              e.status == 'ongoing',
        )
        .where((e) => e.endTime.isAfter(DemoWorld.now))
        .where(
          (e) => blockedPartnerIds == null ||
              !blockedPartnerIds.contains(e.party?.partnerId),
        )
        .toList();

    switch (type) {
      case EventFeedType.newArrivals:
        active.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case EventFeedType.closingSoon:
        active.sort((a, b) => a.startTime.compareTo(b.startTime));
      case EventFeedType.nearest:
        active.sort((a, b) => a.startTime.compareTo(b.startTime));
      case EventFeedType.earlyBird:
        active.sort((a, b) => a.startTime.compareTo(b.startTime));
      case EventFeedType.aiRecommended:
        active.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return active.skip(offset).take(limit).toList();
  }

  @override
  Future<Map<String, dynamic>> getEventFeed({
    required String sortBy,
    Map<String, dynamic>? filters,
    int limit = 20,
    String? cursor,
  }) async {
    final active = demoEvents
        .where(
          (e) =>
              e.status == 'scheduled' ||
              e.status == 'active' ||
              e.status == 'ongoing',
        )
        .where((e) => e.endTime.isAfter(DemoWorld.now))
        .take(limit)
        .toList();
    return {
      'events': active.map((e) => e.toJson()).toList(),
      'has_more': false,
      'next_cursor': null,
    };
  }

  @override
  Future<List<Event>> searchEvents(String query) async {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    return demoEvents
        .where(
          (e) =>
              (e.title?.toLowerCase().contains(q) ?? false) ||
              (e.party?.title.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  @override
  Future<List<TodayActiveEvent>> getTodayActiveEventsForUser(
    String userId,
  ) async {
    if (userId != DemoWorld.userId) return [];
    return demoTodayActiveEvents;
  }

  // ── Checkin / detail queries ──────────────────────────────────────────────

  @override
  Future<Event> getEventById(String eventId) async {
    return demoEvents.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw StateError('DEMO: Event not found: $eventId'),
    );
  }

  @override
  Future<Map<String, bool>> getTicketBalanceStatus(String eventId) async {
    // Demo: all ticket types allowed (no balance restrictions)
    return {};
  }

  @override
  Future<List<Map<String, dynamic>>> getEntryGroupParticipantCounts(
    String eventId,
  ) async {
    // TODO(P6): build per-group counts from demoEventParticipants if needed
    return [];
  }

  // ── Application queries ───────────────────────────────────────────────────

  @override
  Future<List<EventApplication>> getApplicationsByEventId(
    String eventId,
  ) async {
    return demoEventApplications
        .where((a) => a.eventId == eventId)
        .toList();
  }

  @override
  Future<EventApplication?> getApplicationById(String applicationId) async {
    try {
      return demoEventApplications.firstWhere(
        (a) => a.id == applicationId,
      );
    } on StateError {
      return null;
    }
  }

  @override
  Future<EventApplication?> getPurchaseHistoryDetailById(
    String applicationId,
  ) async {
    try {
      final app = demoEventApplications.firstWhere(
        (a) => a.id == applicationId,
      );
      // Attach event for detail page rendering
      final event = demoEvents.firstWhere(
        (e) => e.id == app.eventId,
        orElse: () => throw StateError('DEMO: Event not found'),
      );
      return app.copyWith(event: event);
    } on StateError {
      return null;
    }
  }

  @override
  Future<EventApplication?> getApplication({
    required String eventId,
    required String userId,
  }) async {
    try {
      return demoEventApplications.firstWhere(
        (a) => a.eventId == eventId && a.userId == userId,
      );
    } on StateError {
      return null;
    }
  }

  @override
  Future<List<EventApplication>> getMyPurchaseHistory(String userId) async {
    if (userId != DemoWorld.userId) return [];
    final result = List<EventApplication>.from(demoEventApplications);
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<List<EventApplication>> getMyTickets(String userId) async {
    if (userId != DemoWorld.userId) return [];
    return demoEventApplications
        .where((a) => a.status == 'paid' || a.status == 'approved')
        .toList();
  }

  // ── Partner queries ───────────────────────────────────────────────────────

  @override
  Future<List<Event>> getEventsByPartnerId(String partnerId) async {
    return demoEvents
        .where(
          (e) =>
              e.party?.partnerId == partnerId &&
              (e.status == 'scheduled' ||
                  e.status == 'active' ||
                  e.status == 'ongoing') &&
              e.endTime.isAfter(DemoWorld.now),
        )
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Future<bool> getHasAnyEvents(String partnerId) async {
    return demoEvents.any((e) => e.party?.partnerId == partnerId);
  }

  @override
  Future<List<Event>> getTodayEvents(String partnerId) async {
    final startOfDay = DateTime(DemoWorld.now.year, DemoWorld.now.month, DemoWorld.now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return demoEvents
        .where(
          (e) =>
              e.party?.partnerId == partnerId &&
              e.startTime.isAfter(startOfDay) &&
              e.startTime.isBefore(endOfDay),
        )
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Future<List<Event>> getPartnerFutureEvents(String partnerId) async {
    return demoEvents
        .where(
          (e) =>
              e.party?.partnerId == partnerId &&
              e.startTime.isAfter(DemoWorld.now),
        )
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Future<List<Event>> getUpcomingEvents(String partnerId) async {
    final sevenDaysLater = DemoWorld.offset(const Duration(days: 7));
    return demoEvents
        .where(
          (e) =>
              e.party?.partnerId == partnerId &&
              e.startTime.isAfter(DemoWorld.now) &&
              e.startTime.isBefore(sevenDaysLater) &&
              e.status != 'completed' &&
              e.status != 'cancelled',
        )
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Future<List<Event>> getClosingSoonEvents(String partnerId) async {
    final threeDaysLater = DemoWorld.offset(const Duration(days: 3));
    return demoEvents
        .where(
          (e) =>
              e.party?.partnerId == partnerId &&
              e.startTime.isAfter(DemoWorld.now) &&
              e.startTime.isBefore(threeDaysLater),
        )
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Future<int> getPendingApplicationCount(String partnerId) async {
    // TODO(P6): derive from demoEventApplications filtered by partnerId events
    return 0;
  }

  @override
  Future<int> getRequestedRefundCountForPartner(String partnerId) async {
    return 0;
  }

  // ── Feed analytics (no-op in demo) ───────────────────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getPersonalizedRecommendations({
    required String userId,
    int limit = 10,
  }) async {
    // TODO(P6): map demoEvents to recommendation map shape if needed
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getEventsWithinRadius({
    required double latitude,
    required double longitude,
    int radiusMeters = 5000,
    int limit = 20,
  }) async {
    // TODO(P6): compute distance from demo event locations
    return [];
  }

  @override
  Future<Map<String, dynamic>> getBulkEligibilityData({
    required String userId,
  }) async {
    return {'is_verified': true, 'birth_year': 1995, 'gender': 'male'};
  }
}

// ── PartyRepository ──────────────────────────────────────────────────────────

class _DemoPartyRepository extends PartyRepository {
  _DemoPartyRepository() : super(supabase: const PoisonSupabaseClient());

  @override
  Future<Party?> getPartyById(String partyId) async {
    try {
      return demoParties.firstWhere((p) => p.id == partyId);
    } on StateError {
      return null;
    }
  }

  @override
  Future<List<Party>> getPartiesByPartnerId(String partnerId) async {
    return demoParties.where((p) => p.partnerId == partnerId).toList();
  }

  @override
  Future<List<Party>> getParties() async => demoParties;

  @override
  Future<List<Event>> getEventsByPartyId(String partyId) async {
    return demoEvents.where((e) => e.partyId == partyId).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }
}

// ── TagRepository ─────────────────────────────────────────────────────────────

class _DemoTagRepository extends TagRepository {
  _DemoTagRepository() : super(supabase: const PoisonSupabaseClient());

  @override
  Future<List<Tag>> getFeaturedTags() async {
    return demoTags.where((t) => t.isFeatured).toList();
  }

  @override
  Future<List<Tag>> getTrendingTags({int limit = 10, int days = 7}) async {
    final sorted = List<Tag>.from(demoTags)
      ..sort((a, b) => b.recentCount.compareTo(a.recentCount));
    return sorted.take(limit).toList();
  }

  @override
  Future<List<Tag>> searchTags(String query) async {
    if (query.isEmpty) return demoTags;
    final q = query.toLowerCase();
    return demoTags.where((t) => t.name.toLowerCase().contains(q)).toList();
  }

  @override
  Future<List<Tag>> getTagsByPartyId(String partyId) async {
    try {
      final party = demoParties.firstWhere((p) => p.id == partyId);
      return party.tags ?? [];
    } on StateError {
      return [];
    }
  }

  @override
  Future<List<Tag>> getTagsByIds(List<String> tagIds) async {
    return demoTags.where((t) => tagIds.contains(t.id)).toList();
  }

  @override
  Future<List<Tag>> getUserInterestTags() async {
    // Demo user's interest tags: 음악, 대화, 게임
    return demoTags
        .where((t) => ['음악', '대화', '게임'].contains(t.name))
        .toList();
  }

  @override
  Future<List<Event>> getPartiesByTag(
    String tagId, {
    int limit = 10,
    int offset = 0,
  }) async {
    final tag = demoTags.firstWhere(
      (t) => t.id == tagId,
      orElse: () => throw StateError('DEMO: Tag not found: $tagId'),
    );
    return demoEvents
        .where(
          (e) =>
              e.tags != null && e.tags!.any((t) => t.id == tag.id),
        )
        .skip(offset)
        .take(limit)
        .toList();
  }

  @override
  Future<List<Event>> getTagRecommendations({int limit = 10}) async {
    // Return upcoming events with the demo user's interest tags
    final interestTagNames = {'음악', '대화', '게임'};
    return demoEvents
        .where(
          (e) =>
              e.tags != null &&
              e.tags!.any((t) => interestTagNames.contains(t.name)),
        )
        .take(limit)
        .toList();
  }
}

// ── LocationRepository ────────────────────────────────────────────────────────

class _DemoLocationRepository extends LocationRepository {
  _DemoLocationRepository() : super(supabase: const PoisonSupabaseClient());

  /// All demo locations built inline in demo_parties.dart.
  static final List<Location> _all = List.unmodifiable(
    demoParties
        .map((p) => p.location)
        .whereType<Location>()
        .toList(),
  );

  @override
  Future<Location?> getLocationById(String id) async {
    try {
      return _all.firstWhere((l) => l.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<List<Location>> getLocations(String partnerId) async {
    return _all.where((l) => l.partnerId == partnerId).toList();
  }
}

// ── Domain override list ──────────────────────────────────────────────────────

List<Override> eventDomainOverrides() => [
  eventRepositoryProvider.overrideWith((_) => _DemoEventRepository()),
  partyRepositoryProvider.overrideWith((_) => _DemoPartyRepository()),
  tagRepositoryProvider.overrideWith((_) => _DemoTagRepository()),
  locationRepositoryProvider.overrideWith((_) => _DemoLocationRepository()),
];
