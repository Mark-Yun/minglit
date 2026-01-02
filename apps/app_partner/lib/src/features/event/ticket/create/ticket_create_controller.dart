import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ticket_create_controller.g.dart';

@riverpod
class TicketCreateController extends _$TicketCreateController {
  @override
  FutureOr<void> build() {
    // Initial state
  }

  Future<void> createTicket({
    required String eventId,
    required String name,
    required int price,
    required int quantity,
    String? gender, // 'male' | 'female' | null
    int? minBirthYear,
    int? maxBirthYear,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(ticketRepositoryProvider);

      final conditions = <String, dynamic>{};
      if (gender != null) conditions['gender'] = gender;
      if (minBirthYear != null || maxBirthYear != null) {
        conditions['age_range'] = {
          'min': minBirthYear,
          'max': maxBirthYear,
        }..removeWhere((k, v) => v == null);
      }

      final ticket = Ticket(
        id: '', // DB Generated
        name: name,
        eventId: eventId,
        price: price,
        quantity: quantity,
        conditions: conditions,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createTicket(ticket);
    });
  }
}
