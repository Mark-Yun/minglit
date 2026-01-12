import 'dart:async';

import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_feed_provider.g.dart';

/// **Raw Data Provider**
/// Fetches event data from the server.
/// Uses [keepAlive] with a timer to prevent excessive API calls.
@riverpod
Future<List<Event>> fetchEventFeed(
  Ref ref, {
  required EventFeedType type,
  double? latitude,
  double? longitude,
  int limit = 10,
}) {
  // Cache data for 5 minutes
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), () {
    link.close();
  });
  ref.onDispose(() => timer.cancel());

  final repository = ref.watch(eventRepositoryProvider);

  return repository.getEventsByType(
    type: type,
    latitude: latitude,
    longitude: longitude,
    limit: limit,
  );
}

/// **View Model Provider**
/// Filters the raw event feed based on the current user's status.
/// This provider re-computes when user profile changes, but DOES NOT trigger a new API call
/// because it watches the cached [fetchEventFeedProvider].
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

  // 2. Watch User Profile (for filtering)
  final currentUser = ref.watch(currentUserProfileProvider).value;

  // 3. Apply Filtering Logic
  if (currentUser != null) {
    return events.where((event) {
      final tickets = event.tickets ?? [];
      // Example logic: if tickets exist, show event.
      // Adjust this logic as per business requirements.
      if (tickets.isEmpty) return false;
      return true;
    }).toList();
  }

  return events;
}

@riverpod
Future<Event> eventDetail(Ref ref, String eventId) {
  // Cache detail for 5 minutes
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), () {
    link.close();
  });
  ref.onDispose(() => timer.cancel());

  final repository = ref.watch(eventRepositoryProvider);
  // Implementation in repository: fetch with all relations
  return repository.getEventById(eventId);
}

@riverpod
Future<List<Event>> partyEvents(Ref ref, String partyId) {
  // Cache party events for 5 minutes
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), () {
    link.close();
  });
  ref.onDispose(() => timer.cancel());

  final repository = ref.watch(partyRepositoryProvider);
  return repository.getEventsByPartyId(partyId);
}
