import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ticket_controller.g.dart';

@riverpod
class TicketController extends _$TicketController {
  @override
  FutureOr<void> build() {
    // Initial state
  }

  Future<void> createTicket({
    required String eventId,
    required String name,
    required int price,
    required int quantity,
    List<String> targetEntryGroupIds = const [],
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(ticketRepositoryProvider);

      final ticket = Ticket(
        id: '', // DB Generated
        name: name,
        eventId: eventId,
        price: price,
        quantity: quantity,
        targetEntryGroupIds: targetEntryGroupIds,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createTicket(ticket);
    });
  }

  Future<void> updateTicket({
    required Ticket ticket,
    String? name,
    int? price,
    int? quantity,
    List<String>? targetEntryGroupIds,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(ticketRepositoryProvider);

      final updatedTicket = ticket.copyWith(
        name: name ?? ticket.name,
        price: price ?? ticket.price,
        quantity: quantity ?? ticket.quantity,
        targetEntryGroupIds: targetEntryGroupIds ?? ticket.targetEntryGroupIds,
        updatedAt: DateTime.now(),
      );

      await repo.updateTicket(updatedTicket);
    });
  }
}

@riverpod
Future<Ticket> ticketDetail(Ref ref, String ticketId) async {
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getTicketById(ticketId);
}
