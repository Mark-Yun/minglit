import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_feed_provider.g.dart';

@Riverpod(keepAlive: true)
Future<List<Event>> eventFeed(
  Ref ref, {
  required EventFeedType type,
  double? latitude,
  double? longitude,
  int limit = 10,
}) {
  final repository = ref.watch(eventRepositoryProvider);
  final currentUser = ref.watch(currentUserProfileProvider).value;

  return repository.getEventsByType(
    type: type,
    currentUser: currentUser,
    latitude: latitude,
    longitude: longitude,
    limit: limit,
  );
}

@Riverpod(keepAlive: true)
Future<Event> eventDetail(Ref ref, String eventId) {
  final repository = ref.watch(eventRepositoryProvider);
  // Implementation in repository: fetch with all relations
  return repository.getEventById(eventId);
}

@Riverpod(keepAlive: true)
Future<List<Event>> partyEvents(Ref ref, String partyId) {
  final repository = ref.watch(partyRepositoryProvider);
  return repository.getEventsByPartyId(partyId);
}
