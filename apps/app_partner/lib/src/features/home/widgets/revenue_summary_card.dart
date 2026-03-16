import 'dart:async';

import 'package:app_partner/src/features/party/party_providers.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Revenue summary card — displays current month net settlement amount.
/// Loads data from SettlementRepository.getSettlementDashboard().
class RevenueSummaryCard extends ConsumerStatefulWidget {
  const RevenueSummaryCard({super.key});

  @override
  ConsumerState<RevenueSummaryCard> createState() => _RevenueSummaryCardState();
}

class _RevenueSummaryCardState extends ConsumerState<RevenueSummaryCard> {
  int? _currentMonthNet;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    try {
      final partner = await ref.read(currentPartnerInfoProvider.future);
      if (partner == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final now = DateTime.now();
      final repo = ref.read(settlementRepositoryProvider);
      final data = await repo.getSettlementDashboard(
        partnerId: partner.id,
        periodStart: DateTime(now.year, now.month),
        periodEnd: DateTime(now.year, now.month + 1, 0),
      );
      if (mounted) {
        setState(() {
          _currentMonthNet = data['completed_net_total'] as int? ?? 0;
          _isLoading = false;
        });
      }
    } on Exception catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formatter = NumberFormat.currency(locale: 'ko_KR', symbol: '₩');

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MinglitRadius.card),
      ),
      child: InkWell(
        onTap: () => const SettlementRoute().push<void>(context),
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
              const SizedBox(height: 8),
              if (_isLoading)
                SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                )
              else
                Text(
                  formatter.format(_currentMonthNet ?? 0),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
