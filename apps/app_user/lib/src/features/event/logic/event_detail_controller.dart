import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_detail_controller.g.dart';

@riverpod
class EventDetailController extends _$EventDetailController {
  @override
  FutureOr<Event> build(String eventId) async {
    final repository = ref.watch(eventRepositoryProvider);
    return repository.getEventById(eventId);
  }
}

@riverpod
Future<Map<String, int>> entryGroupParticipantCounts(
  Ref ref,
  String eventId,
) async {
  final repo = ref.read(eventRepositoryProvider);
  final list = await repo.getEntryGroupParticipantCounts(eventId);
  return {
    for (final item in list)
      item['entry_group_id'] as String:
          (item['participant_count'] as num).toInt(),
  };
}
