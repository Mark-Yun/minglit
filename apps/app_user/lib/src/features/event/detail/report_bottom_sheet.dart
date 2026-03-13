import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

Future<void> showReportBottomSheet(
  BuildContext context,
  WidgetRef ref,
  String partnerId,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ReportSheet(partnerId: partnerId),
  );
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({required this.partnerId});
  final String partnerId;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  ReportReason? _selectedReason;
  final _descriptionController = TextEditingController();
  bool _submitting = false;

  static const Map<ReportReason, String> _reasonLabels = {
    ReportReason.sexualContent: '선정적인 콘텐츠',
    ReportReason.falseInformation: '허위 또는 과장된 정보',
    ReportReason.noShow: '노쇼 / 이벤트 미진행',
    ReportReason.fraud: '사기 또는 부당 청구',
    ReportReason.other: '기타',
  };

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(socialRepositoryProvider)
          .reportPartner(
            partnerId: widget.partnerId,
            reason: _selectedReason!.value,
            description: _selectedReason == ReportReason.other
                ? _descriptionController.text.trim()
                : null,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('신고가 접수되었습니다')),
        );
      }
    } on Object catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('신고 처리 중 오류가 발생했습니다')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: MinglitSpacing.medium),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.medium,
            ),
            child: Text(
              '신고하기',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: MinglitSpacing.xsmall),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.medium,
            ),
            child: Text(
              '신고 이유를 선택해주세요',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
          for (final reason in ReportReason.values)
            RadioListTile<ReportReason>(
              title: Text(_reasonLabels[reason] ?? reason.name),
              value: reason,
              // ignore: deprecated_member_use, RadioGroup migration pending
              groupValue: _selectedReason,
              // ignore: deprecated_member_use, RadioGroup migration pending
              onChanged: (v) => setState(() => _selectedReason = v),
            ),
          if (_selectedReason == ReportReason.other)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MinglitSpacing.medium,
              ),
              child: TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: '상세 사유를 입력해주세요',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            child: FilledButton(
              onPressed: _selectedReason != null && !_submitting
                  ? _submit
                  : null,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: MinglitCircularProgressIndicator(),
                    )
                  : const Text('신고하기'),
            ),
          ),
        ],
      ),
    );
  }
}
