import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:minglit_kit/minglit_kit.dart';

final partnerAccountDeletionGuardProvider =
    FutureProvider<PartnerAccountDeletionGuard>((ref) async {
      final partner = await ref.watch(currentPartnerInfoProvider.future);
      if (partner == null) {
        return const PartnerAccountDeletionGuard();
      }

      final eventRepository = ref.watch(eventRepositoryProvider);
      final settlementRepository = ref.watch(settlementRepositoryProvider);

      final activeEvents = await eventRepository.getEventsByPartnerId(
        partner.id,
      );
      final settlementDashboard = await settlementRepository
          .getSettlementDashboard(partnerId: partner.id);
      final pendingRefundCount = await eventRepository
          .getRequestedRefundCountForPartner(partner.id);

      final statusCounts =
          (settlementDashboard['status_counts'] as Map?)?.cast<String, int>() ??
          const <String, int>{};

      final unsettledCount = statusCounts.entries
          .where((entry) => entry.key != 'COMPLETED' && entry.key != 'CANCELED')
          .fold<int>(0, (sum, entry) => sum + entry.value);

      return PartnerAccountDeletionGuard(
        activeEventCount: activeEvents.length,
        unsettledSettlementCount: unsettledCount,
        pendingRefundCount: pendingRefundCount,
      );
    });

class PartnerAccountDeletionGuard {
  const PartnerAccountDeletionGuard({
    this.activeEventCount = 0,
    this.unsettledSettlementCount = 0,
    this.pendingRefundCount = 0,
  });

  final int activeEventCount;
  final int unsettledSettlementCount;
  final int pendingRefundCount;

  bool get hasBlockingIssues =>
      activeEventCount > 0 ||
      unsettledSettlementCount > 0 ||
      pendingRefundCount > 0;
}
