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
      final repo = ref.read(partyRepositoryProvider);

      final ticket = EventTicket(
        id: '', // DB Generated
        eventId: eventId,
        name: name,
        price: price,
        quantity: quantity,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        gender: gender,
        minBirthYear: minBirthYear,
        maxBirthYear: maxBirthYear,
      );

      await repo.createTicket(ticket);
    });
  }
}
