import 'package:app_user/src/features/account_deletion/account_deletion_flow.dart';
import 'package:app_user/src/features/account_deletion/logic/account_deletion_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class DeletionInfoPage extends ConsumerWidget {
  const DeletionInfoPage({
    this.reasonCode,
    this.reasonText,
    super.key,
  });

  final String? reasonCode;
  final String? reasonText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final coordinator = ref.read(accountDeletionCoordinatorProvider);
    final reason = buildWithdrawalReason(
      reasonCode: reasonCode,
      reasonText: reasonText,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('탈퇴 전 확인')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(MinglitSpacing.large),
                children: [
                  if (reason != null) ...[
                    Container(
                      padding: const EdgeInsets.all(MinglitSpacing.medium),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '선택한 탈퇴 사유',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                          const SizedBox(height: MinglitSpacing.xsmall),
                          Text(
                            withdrawalReasonLabel(reason.reasonCode),
                            style: theme.textTheme.titleSmall,
                          ),
                          if (reason.detail != null) ...[
                            const SizedBox(height: MinglitSpacing.xsmall),
                            Text(reason.detail!),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: MinglitSpacing.large),
                  ],
                  const _InfoSection(
                    title: '삭제되는 정보',
                    items: [
                      '프로필, 관심사, 차단 목록, 알림 설정',
                      '매칭과 피드 노출을 위한 개인화 데이터',
                      '활동 기록과 저장된 앱 내 설정',
                    ],
                  ),
                  const SizedBox(height: MinglitSpacing.medium),
                  const _InfoSection(
                    title: '법정 보존 정보',
                    items: [
                      '전자상거래 관련 결제·계약 기록',
                      '분쟁 대응을 위한 최소한의 증빙 정보',
                      '재가입 제한을 위한 식별 해시 정보',
                    ],
                  ),
                  const SizedBox(height: MinglitSpacing.medium),
                  Container(
                    padding: const EdgeInsets.all(MinglitSpacing.medium),
                    decoration: BoxDecoration(
                      color: MinglitColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '유예 기간 안내',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: MinglitColors.error,
                          ),
                        ),
                        const SizedBox(height: MinglitSpacing.xsmall),
                        Text(
                          '탈퇴 요청 후 7일 동안은 다시 로그인해 계정을 복구할 수 있어요. '
                          '유예 기간이 지나면 계정이 영구 삭제되고 30일 동안 재가입이 제한될 수 있어요.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
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
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => coordinator.pushVerify(reason: reason),
                  child: const Text('계속 진행'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: MinglitSpacing.small),
            for (final item in items) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.circle, size: 8),
                  ),
                  const SizedBox(width: MinglitSpacing.small),
                  Expanded(child: Text(item)),
                ],
              ),
              const SizedBox(height: MinglitSpacing.small),
            ],
          ],
        ),
      ),
    );
  }
}
