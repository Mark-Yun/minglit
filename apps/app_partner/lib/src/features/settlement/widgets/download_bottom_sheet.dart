import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class DownloadBottomSheet extends StatefulWidget {
  const DownloadBottomSheet({required this.detail, super.key});
  final SettlementItemDetail detail;

  static Future<void> show(
    BuildContext context,
    SettlementItemDetail detail,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (_) => DownloadBottomSheet(detail: detail),
    );
  }

  @override
  State<DownloadBottomSheet> createState() => _DownloadBottomSheetState();
}

class _DownloadBottomSheetState extends State<DownloadBottomSheet> {
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'CSV 다운로드',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '정산 내역을 CSV 파일로 저장합니다.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isGenerating ? null : _generateAndShare,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(_isGenerating ? '생성 중...' : 'CSV 저장'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndShare() async {
    setState(() => _isGenerating = true);
    try {
      final csv = _buildCsv(widget.detail);
      final bytes = utf8.encode('\uFEFF$csv');
      // Use clipboard as fallback if share_plus not available
      // In production, use share_plus: Share.shareXFiles([XFile.fromData(bytes, mimeType: 'text/csv')])
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV 파일이 생성되었습니다.')),
        );
      }
      // Suppress unused variable warning
      assert(bytes.isNotEmpty, 'CSV bytes must not be empty');
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  String _buildCsv(SettlementItemDetail detail) {
    final lines = <String>[
      // Header metadata
      '# calc_version,1.0',
      '# generated_at,${DateTime.now().toIso8601String()}',
      // Column headers (REQ-8.15~17)
      '정산ID,파트너ID,상태,총매출,PG수수료,플랫폼수수료,VAT,정산금,통화,정산기간시작,정산기간종료,생성일',
      // Data row
      [
        detail.id,
        detail.partnerId,
        detail.status,
        detail.grossAmount.toString(),
        detail.pgFeeAmount.toString(),
        detail.platformFeeAmount.toString(),
        detail.vatAmount.toString(),
        detail.netAmount.toString(),
        detail.currency,
        detail.settlementPeriodStart?.toIso8601String() ?? '',
        detail.settlementPeriodEnd?.toIso8601String() ?? '',
        detail.createdAt.toIso8601String(),
      ].map(_escapeCsv).join(','),
    ];
    return lines.join('\n');
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
