import 'dart:async';

import 'package:minglit_kit/src/data/models/event.dart';
import 'package:minglit_kit/src/data/models/event_feed_type.dart';
import 'package:minglit_kit/src/data/repositories/event_repository.dart';
import 'package:minglit_kit/src/data/repositories/party_repository.dart';
import 'package:minglit_kit/src/logic/providers/user_profile_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_feed_provider.g.dart';

/// **Raw Data Provider**
/// Fetches event data from the server.
/// Uses `ref.keepAlive()` with a timer to prevent excessive API calls.
@riverpod
Future<List<Event>> fetchEventFeed(
  Ref ref, {
  required EventFeedType type,
  double? latitude,
  double? longitude,
  int limit = 10,
  int offset = 0,
}) {
  // Cache data for 5 minutes
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), link.close);
  ref.onDispose(timer.cancel);

  final repository = ref.watch(eventRepositoryProvider);

  return repository.getEventsByType(
    type: type,
    latitude: latitude,
    longitude: longitude,
    limit: limit,
    offset: offset,
  );
}

/// **View Model Provider**
/// Filters the raw event feed based on the current user's status.
/// This provider re-computes when user profile changes, but DOES NOT trigger
/// a new API call because it watches the cached [fetchEventFeedProvider].
@riverpod
Future<List<Event>> eventFeed(
  Ref ref, {
  required EventFeedType type,
  double? latitude,
  double? longitude,
  int limit = 10,
}) async {
  // 1. Watch the raw data (Cached)
  final events = await ref.watch(
    fetchEventFeedProvider(
      type: type,
      latitude: latitude,
      longitude: longitude,
      limit: limit,
    ).future,
  );

  // 2. Watch User Profile (triggers re-computation on profile change)
  // ignore: unused_local_variable — kept as extension point for future filtering
  final currentUser = ref.watch(currentUserProfileProvider).value;

  // 3. Apply Filtering Logic
  // Fix #778: Removed broken ticket filter that hid events without tickets
  // for logged-in users. Free events and new events may not have ticket
  // configurations. This provider remains as a business-logic extension point
  // for future user-specific filtering (e.g., personalization, visibility).
  return events;
}

@riverpod
/// Fetches detailed event data by [eventId].
Future<Event> eventDetail(Ref ref, String eventId) {
  // Cache detail for 5 minutes
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), link.close);
  ref.onDispose(timer.cancel);

  final repository = ref.watch(eventRepositoryProvider);
  // Implementation in repository: fetch with all relations
  return repository.getEventById(eventId);
}

@riverpod
/// Fetches events associated with the given [partyId].
Future<List<Event>> partyEvents(Ref ref, String partyId) {
  // Cache party events for 5 minutes
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), link.close);
  ref.onDispose(timer.cancel);

  final repository = ref.watch(partyRepositoryProvider);
  return repository.getEventsByPartyId(partyId);
}

@riverpod
/// Fetches upcoming events for a specific partner.
Future<List<Event>> partnerEvents(
  Ref ref, {
  required String partnerId,
}) {
  // Cache partner events for 5 minutes
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), link.close);
  ref.onDispose(timer.cancel);

  final repository = ref.watch(eventRepositoryProvider);
  return repository.getEventsByPartnerId(partnerId);
}
