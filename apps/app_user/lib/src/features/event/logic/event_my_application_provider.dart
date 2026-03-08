import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_my_application_provider.g.dart';

@riverpod
Future<EventApplication?> eventMyApplication(
  Ref ref,
  String eventId,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final repository = ref.watch(eventRepositoryProvider);
  return repository.getApplication(eventId: eventId, userId: user.id);
}
