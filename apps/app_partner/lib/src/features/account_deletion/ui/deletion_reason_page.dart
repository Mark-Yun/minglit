import 'package:app_partner/src/features/account_deletion/account_deletion_coordinator.dart';
import 'package:app_partner/src/features/account_deletion/logic/account_deletion_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:minglit_kit/minglit_kit.dart';

class DeletionReasonPage extends ConsumerStatefulWidget {
  const DeletionReasonPage({super.key});

  @override
  ConsumerState<DeletionReasonPage> createState() => _DeletionReasonPageState();
}

class _DeletionReasonPageState extends ConsumerState<DeletionReasonPage> {
  final TextEditingController _detailController = TextEditingController();
  WithdrawalReasonCode? _selectedCode;

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coordinator = ref.read(accountDeletionCoordinatorProvider);
    final selectedReason = buildWithdrawalReason(
      reasonCode: _selectedCode == null
          ? null
          : encodeWithdrawalReasonCode(_selectedCode!),
      reasonText: _selectedCode == WithdrawalReasonCode.other
          ? _detailController.text
          : null,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('탈퇴 사유')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(MinglitSpacing.large),
                children: [
                  Text(
                    '파트너 탈퇴 이유를 알려주시면 운영 경험 개선에 도움이 돼요.',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: MinglitSpacing.small),
                  Text(
                    '선택하지 않고 계속 진행해도 괜찮아요.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: MinglitSpacing.large),
                  for (final option in accountDeletionReasonOptions) ...[
                    Card(
                      margin: const EdgeInsets.only(
                        bottom: MinglitSpacing.small,
                      ),
                      child: RadioListTile<WithdrawalReasonCode>(
                        value: option.code,
                        groupValue: _selectedCode,
                        onChanged: (value) {
                          setState(() {
                            _selectedCode = value;
                            if (_selectedCode != WithdrawalReasonCode.other) {
                              _detailController.clear();
                            }
                          });
                        },
                        title: Text(option.title),
                        subtitle: Text(option.description),
                      ),
                    ),
                  ],
                  if (_selectedCode == WithdrawalReasonCode.other) ...[
                    const SizedBox(height: MinglitSpacing.small),
                    MinglitTextField(
                      label: '상세 사유',
                      controller: _detailController,
                      hintText: '남겨주고 싶은 내용을 입력해주세요',
                      maxLines: 4,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(200),
                      ],
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MinglitSpacing.large,
                MinglitSpacing.small,
                MinglitSpacing.large,
                MinglitSpacing.large,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextButton(
                    onPressed: coordinator.pushInfo,
                    child: const Text('선택하지 않고 계속하기'),
                  ),
                  const SizedBox(height: MinglitSpacing.small),
                  FilledButton(
                    onPressed: selectedReason == null
                        ? null
                        : () => coordinator.pushInfo(reason: selectedReason),
                    child: const Text('다음'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
