import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_detail_controller.g.dart';

@riverpod
Future<Event> eventDetail(Ref ref, String eventId) async {
  final repo = ref.watch(partyRepositoryProvider);
  return repo.getEventById(eventId);
}

@riverpod
Future<List<Ticket>> eventTickets(Ref ref, String eventId) async {
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getTicketsByEventId(eventId);
}
