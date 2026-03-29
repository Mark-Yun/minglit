import 'package:app_partner/src/features/home/partner_home_coordinator.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'revenue_summary_card.g.dart';

/// Loads current month net settlement amount from SettlementRepository.
@riverpod
Future<int> currentMonthNet(Ref ref) async {
  final partner = await ref.read(currentPartnerInfoProvider.future);
  if (partner == null) return 0;
  final now = DateTime.now();
  final repo = ref.read(settlementRepositoryProvider);
  final data = await repo.getSettlementDashboard(
    partnerId: partner.id,
    periodStart: DateTime(now.year, now.month),
    periodEnd: DateTime(now.year, now.month + 1, 0),
  );
  return data['completed_net_total'] as int? ?? 0;
}

/// Revenue summary card — displays current month net settlement amount.
class RevenueSummaryCard extends ConsumerWidget {
  const RevenueSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formatter = NumberFormat.currency(locale: 'ko_KR', symbol: '₩');
    final currentMonthNetAsync = ref.watch(currentMonthNetProvider);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MinglitRadius.card),
      ),
      child: InkWell(
        onTap: () =>
            ref.read(partnerHomeCoordinatorProvider).goToSettlement(),
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(MinglitSpacing.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '이번 달 예상 매출',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: MinglitSpacing.small),
              currentMonthNetAsync.when(
                data: (amount) => Text(
                  formatter.format(amount),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                loading: () => SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                ),
                error: (error, stackTrace) => Text(
                  formatter.format(0),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
