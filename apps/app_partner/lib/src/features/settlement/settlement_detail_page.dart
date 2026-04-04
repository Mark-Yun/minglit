import 'dart:async' show unawaited;

import 'package:app_partner/src/features/settlement/settlement_coordinator.dart';
import 'package:app_partner/src/features/settlement/widgets/download_bottom_sheet.dart';
import 'package:app_partner/src/features/settlement/widgets/settlement_status_badge.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

class SettlementDetailPage extends ConsumerStatefulWidget {
  const SettlementDetailPage({required this.itemId, super.key});
  final String itemId;

  @override
  ConsumerState<SettlementDetailPage> createState() =>
      _SettlementDetailPageState();
}

class _SettlementDetailPageState extends ConsumerState<SettlementDetailPage> {
  SettlementItemDetail? _detail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDetail());
  }

  Future<void> _loadDetail() async {
    try {
      final repo = ref.read(settlementRepositoryProvider);
      final detail = await repo.getSettlementItemDetail(widget.itemId);
      if (mounted) {
        setState(() {
          _detail = detail;
          _isLoading = false;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('정산 상세')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(MinglitSpacing.medium),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: MinglitSpacing.medium),
                    Text(
                      '오류가 발생했습니다',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: MinglitSpacing.small),
                    Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: MinglitSpacing.medium),
                    FilledButton(
                      onPressed: _loadDetail,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            )
          : _detail == null
          ? const Center(child: Text('정산 항목을 찾을 수 없습니다.'))
          : _DetailContent(detail: _detail!),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.detail});
  final SettlementItemDetail detail;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusMessageCard(status: detail.status),
          const SizedBox(height: MinglitSpacing.medium),
          AmountBreakdown(detail: detail),
          const SizedBox(height: MinglitSpacing.medium),
          if (detail.histories.isNotEmpty) ...[
            StatusTimeline(histories: detail.histories),
            const SizedBox(height: MinglitSpacing.medium),
          ],
          ActionButtons(detail: detail),
        ],
      ),
    );
  }
}

class StatusMessageCard extends StatelessWidget {
  const StatusMessageCard({required this.status, super.key});
  final String status;

  static const _messages = {
    'PENDING': '정산이 확정되기를 기다리고 있습니다.',
    'HOLD': '정산이 보류 중입니다. 지원센터에 문의해 주세요.',
    'READY': '정산이 확정되었습니다. 곧 지급이 시작됩니다.',
    'PROCESSING': '지급이 진행 중입니다.',
    'COMPLETED': '지급이 완료되었습니다.',
    'FAILED': '지급에 실패했습니다. 계좌 정보를 확인해 주세요.',
    'CANCELED': '정산이 취소되었습니다.',
  };

  @override
  Widget build(BuildContext context) {
    final message = _messages[status] ?? '상태를 확인 중입니다.';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Row(
          children: [
            SettlementStatusBadge(
              status: SettlementStatus.fromString(status),
              compact: false,
            ),
            const SizedBox(width: MinglitSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AmountBreakdown extends StatelessWidget {
  const AmountBreakdown({required this.detail, super.key});
  final SettlementItemDetail detail;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('금액 내역', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: MinglitSpacing.sm),
            _Row('총 매출', fmt.format(detail.grossAmount)),
            _Row('PG 수수료', '-${fmt.format(detail.pgFeeAmount)}'),
            _Row('플랫폼 수수료', '-${fmt.format(detail.platformFeeAmount)}'),
            _Row('VAT', '-${fmt.format(detail.vatAmount)}'),
            const Divider(),
            _Row(
              '정산금',
              '₩${fmt.format(detail.netAmount)}',
              bold: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          )
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.xsmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class StatusTimeline extends StatelessWidget {
  const StatusTimeline({required this.histories, super.key});
  final List<SettlementHistoryEntry> histories;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('처리 이력', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: MinglitSpacing.sm),
            ...histories.map((h) => _TimelineItem(entry: h)),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.entry});
  final SettlementHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MM/dd HH:mm');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.xsmall2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: MinglitColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: MinglitSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.fromStatus} → ${entry.toStatus}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  fmt.format(entry.createdAt.toLocal()),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ActionButtons extends ConsumerWidget {
  const ActionButtons({required this.detail, super.key});
  final SettlementItemDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (detail.status == 'FAILED' && detail.retryable)
          FilledButton.icon(
            onPressed: () => _retryPayout(context, ref),
            icon: const Icon(Icons.refresh),
            label: const Text('재지급 요청'),
          ),
        const SizedBox(height: MinglitSpacing.small),
        OutlinedButton.icon(
          onPressed: () => _downloadCsv(context),
          icon: const Icon(Icons.download),
          label: const Text('CSV 다운로드'),
        ),
      ],
    );
  }

  Future<void> _retryPayout(BuildContext context, WidgetRef ref) async {
    if (detail.payoutId == null) return;
    final partner = await ref.read(currentPartnerInfoProvider.future);
    if (partner == null) return;
    await ref
        .read(settlementCoordinatorProvider.notifier)
        .retryPayout(
          context,
          payoutId: detail.payoutId!,
          partnerId: partner.id,
        );
  }

  void _downloadCsv(BuildContext context) {
    unawaited(DownloadBottomSheet.show(context, detail));
  }
}
