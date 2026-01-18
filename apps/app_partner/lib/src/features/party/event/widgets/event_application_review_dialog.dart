import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class EventApplicationReviewDialog extends StatefulWidget {
  const EventApplicationReviewDialog({
    required this.application,
    super.key,
  });

  final EventApplication application;

  @override
  State<EventApplicationReviewDialog> createState() =>
      _EventApplicationReviewDialogState();
}

class _EventApplicationReviewDialogState
    extends State<EventApplicationReviewDialog> {
  String? _selectedReason;
  final _customReasonController = TextEditingController();
  bool _isCustomReason = false;

  final List<String> _presetReasons = [
    '증빙 서류 식별 불가: 사진이 흐릿하거나 잘려서 확인할 수 없습니다.',
    '자격 요건 불충분: 제출하신 서류가 파티 자격 요건을 충족하지 않습니다.',
    '정원 초과: 해당 그룹의 정원이 모두 찼습니다.',
  ];

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.application.user;
    final submission = widget.application.submission;

    return AlertDialog(
      title: const Text('참가 신청 심사'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // User Info
            Text(
              '신청자 정보',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: MinglitSpacing.small),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                child: Text(user?.name.characters.first ?? '?'),
              ),
              title: Text(user?.name ?? '익명'),
              subtitle: Text(
                '${user?.gender == 'male' ? "남" : "여"} · ${user?.birthDate ?? ""}',
              ),
            ),
            const Divider(),

            // Verification Data
            if (submission != null) ...[
              const SizedBox(height: MinglitSpacing.small),
              Text(
                '제출 데이터',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: MinglitSpacing.small),
              ...submission.snapshotData.entries.map((
                MapEntry<String, dynamic> entry,
              ) {
                final key = entry.key;
                final value = entry.value;
                if (value is String &&
                    (value.startsWith('http') || value.contains('/'))) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: MinglitSpacing.small,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(key, style: theme.textTheme.labelSmall),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            MinglitRadius.small,
                          ),
                          child: Image.network(
                            value,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  height: 100,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image),
                                ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(key),
                  subtitle: Text(value.toString()),
                );
              }),
              const Divider(),
            ],

            // Rejection Section
            const SizedBox(height: MinglitSpacing.small),
            Text(
              '거절 사유 (거절 시 필수)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
            ),
            ..._presetReasons.map(
              (reason) => RadioListTile<String>(
                title: Text(reason, style: theme.textTheme.bodySmall),
                value: reason,
                // ignore: deprecated_member_use, Reason: Flutter 3.32
                groupValue: _isCustomReason ? null : _selectedReason,
                // ignore: deprecated_member_use, Reason: Flutter 3.32
                onChanged: (val) {
                  setState(() {
                    _selectedReason = val;
                    _isCustomReason = false;
                  });
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            RadioListTile<bool>(
              title: const Text('직접 입력', style: TextStyle(fontSize: 12)),
              value: true,
              // ignore: deprecated_member_use, Reason: Flutter 3.32
              groupValue: _isCustomReason,
              // ignore: deprecated_member_use, Reason: Flutter 3.32
              onChanged: (val) {
                setState(() {
                  _isCustomReason = true;
                  _selectedReason = null;
                });
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            if (_isCustomReason)
              TextField(
                controller: _customReasonController,
                decoration: const InputDecoration(
                  hintText: '사유를 직접 입력해주세요',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () => _handleReview(context, 'rejected'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.errorContainer,
            foregroundColor: theme.colorScheme.onErrorContainer,
          ),
          child: const Text('거절'),
        ),
        Consumer(
          builder: (context, ref, _) => ElevatedButton(
            onPressed: () => _handleReview(context, 'approved'),
            child: const Text('승인'),
          ),
        ),
      ],
    );
  }

  Future<void> _handleReview(BuildContext context, String status) async {
    final reason = _isCustomReason
        ? _customReasonController.text
        : _selectedReason;

    if (status == 'rejected' && (reason == null || reason.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('거절 사유를 선택하거나 입력해주세요.')),
      );
      return;
    }

    // Pass the logic to controller via Provider (requires a way to get ref)
    // Actually, I can use a Navigator pop with result or use a context-based provider.
    Navigator.pop(context, {'status': status, 'reason': reason});
  }
}
