import 'package:app_user/src/features/payment/logic/purchase_history_controller.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'purchase_history_detail_controller.g.dart';

/// Fetches a single application with full event+ticket data for the detail
/// page. Tries the cached list first to avoid an extra round-trip when the
/// user navigates from PurchaseHistoryPage.
@riverpod
Future<EventApplication?> purchaseHistoryDetail(
  Ref ref,
  String applicationId,
) async {
  // Prefer cached list so the detail screen opens instantly.
  final cached = switch (ref.watch(purchaseHistoryControllerProvider)) {
    AsyncData(:final value) => value,
    _ => null,
  };
  if (cached != null) {
    final found = cached
        .where((EventApplication a) => a.id == applicationId)
        .firstOrNull;
    if (found != null) return found;
  }

  final repository = ref.watch(eventRepositoryProvider);
  return repository.getPurchaseHistoryDetailById(applicationId);
}
