import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_now_bar_controller.g.dart';

/// Fetches today's active events for the current user.
///
/// Returns events where the user is a participant and the event is within
/// the active window (start_time - 3h to end_time).
/// Cancelled events are included; refunded participants are excluded.
@riverpod
Future<List<TodayActiveEvent>> todayActiveEvents(Ref ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final repository = ref.watch(eventRepositoryProvider);
  return repository.getTodayActiveEventsForUser(user.id);
}
