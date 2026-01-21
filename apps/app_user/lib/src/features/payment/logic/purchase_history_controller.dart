import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'purchase_history_controller.g.dart';

/// **Purchase History Controller**
///
/// Manages the state of the user's purchase history.
/// Fetches data from EventRepository.
@riverpod
class PurchaseHistoryController extends _$PurchaseHistoryController {
  @override
  FutureOr<List<EventApplication>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      // Return empty list or throw error depending on UX.
      return [];
    }

    final repository = ref.watch(eventRepositoryProvider);
    return repository.getMyPurchaseHistory(user.id);
  }

  // Future features: infinite scroll, filtering, etc.
}
