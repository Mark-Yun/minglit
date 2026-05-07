import 'package:app_partner/src/logic/event_application_logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/minglit_kit.dart';

// Fix #2272: deferred batch confirm — commits all carousel local marks at once
class EventApplicationReviewConfirmPage extends ConsumerStatefulWidget {
  const EventApplicationReviewConfirmPage({
    required this.eventId,
    super.key,
  });

  final String eventId;

  @override
  ConsumerState<EventApplicationReviewConfirmPage> createState() => _State();
}

class _State extends ConsumerState<EventApplicationReviewConfirmPage> {
  bool _isSubmitting = false;

  Future<void> _submit(Map<String, ReviewMark> marks) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final controller = ref.read(
        eventApplicationReviewControllerProvider.notifier,
      );
      for (final entry in marks.entries) {
        await controller.reviewApplication(
          applicationId: entry.key,
          status: entry.value.status,
          reason: entry.value.reason,
        );
      }
      ref.read(reviewMarkingsProvider.notifier).clearAll();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('제출 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final marks = ref.watch(reviewMarkingsProvider);
    final approvedCount = marks.values
        .where((m) => m.status == 'approved')
        .length;
    final rejectedCount = marks.values
        .where((m) => m.status == 'rejected')
        .length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('심사 확인'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MinglitSpacing.screenEdge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: MinglitSpacing.large),
              Text(
                '심사 결과 요약',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: MinglitSpacing.large),
              _SummaryRow(
                label: '승인',
                count: approvedCount,
                color: MinglitColors.success,
              ),
              const SizedBox(height: MinglitSpacing.small),
              _SummaryRow(
                label: '거절',
                count: rejectedCount,
                color: MinglitColors.error,
              ),
              const Spacer(),
              FilledButton(
                onPressed: (marks.isEmpty || _isSubmitting)
                    ? null
                    : () => _submit(marks),
                child: _isSubmitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                        ),
                      )
                    : Text('${marks.length}건 최종 제출'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: MinglitSpacing.small),
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        const Spacer(),
        Text(
          '$count건',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
