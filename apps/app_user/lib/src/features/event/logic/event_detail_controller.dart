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
