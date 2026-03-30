import 'package:app_partner/src/features/account_deletion/account_deletion_coordinator.dart';
import 'package:app_partner/src/features/account_deletion/logic/account_deletion_flow.dart';
import 'package:app_partner/src/features/account_deletion/partner_account_deletion_guard.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class DeletionVerifyPage extends ConsumerStatefulWidget {
  const DeletionVerifyPage({
    this.reasonCode,
    this.reasonText,
    super.key,
  });

  final String? reasonCode;
  final String? reasonText;

  @override
  ConsumerState<DeletionVerifyPage> createState() => _DeletionVerifyPageState();
}

class _DeletionVerifyPageState extends ConsumerState<DeletionVerifyPage> {
  final TextEditingController _passwordController = TextEditingController();
  String? _passwordErrorText;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final deletionState = ref.watch(accountDeletionControllerProvider);
    final guardState = ref.watch(partnerAccountDeletionGuardProvider);
    final isLoading = deletionState.isLoading;
    final reason = buildWithdrawalReason(
      reasonCode: widget.reasonCode,
      reasonText: widget.reasonText,
    );

    if (user == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final isPasswordUser = usesPasswordAuth(user);
    final blockerData = guardState.value;
    final isBlocked = blockerData?.hasBlockingIssues ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('본인 확인')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(MinglitSpacing.large),
                children: [
                  Text(
                    '파트너 탈퇴 전에 본인 확인이 필요해요.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: MinglitSpacing.small),
                  Text(
                    '활성 이벤트, 미정산 금액, 환불 대기 건이 없어야 탈퇴를 요청할 수 있어요.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: MinglitSpacing.large),
                  if (reason != null)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.check_circle_outline),
                        title: const Text('선택한 탈퇴 사유'),
                        subtitle: Text(
                          withdrawalReasonLabel(reason.reasonCode),
                        ),
                      ),
                    ),
                  if (reason != null)
                    const SizedBox(height: MinglitSpacing.medium),
                  _PartnerDeletionGuardCard(guardState: guardState),
                  const SizedBox(height: MinglitSpacing.medium),
                  if (isPasswordUser)
                    MinglitTextField(
                      label: '비밀번호',
                      controller: _passwordController,
                      obscureText: true,
                      errorText: _passwordErrorText,
                      hintText: '현재 비밀번호를 입력해주세요',
                      onChanged: (_) {
                        if (_passwordErrorText != null) {
                          setState(() {
                            _passwordErrorText = null;
                          });
                        }
                      },
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(MinglitSpacing.medium),
                        child: Text(
                          '소셜 로그인 계정은 다음 단계에서 재인증이 진행돼요.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
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
                  onPressed: isLoading || isBlocked
                      ? null
                      : () => _submitDeletion(
                          context,
                          isPasswordUser: isPasswordUser,
                          reason: reason,
                        ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('탈퇴 요청'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitDeletion(
    BuildContext context, {
    required bool isPasswordUser,
    required WithdrawalReason? reason,
  }) async {
    final password = _passwordController.text.trim();
    if (isPasswordUser && password.isEmpty) {
      setState(() {
        _passwordErrorText = '비밀번호를 입력해주세요.';
      });
      return;
    }

    final controller = ref.read(accountDeletionControllerProvider.notifier);
    try {
      await controller.reauthenticate(isPasswordUser ? password : null);
      if (!context.mounted) return;

      final confirmed = await context.showMinglitConfirm(
        title: '정말 탈퇴할까요?',
        message: '탈퇴 요청 후 7일 동안은 다시 로그인해 계정을 복구할 수 있어요.',
        confirmLabel: '탈퇴 요청',
        cancelLabel: '돌아가기',
      );
      if (!confirmed || !context.mounted) return;

      await controller.requestDeletion(reason: reason);
      if (!context.mounted) return;

      ref.read(accountDeletionCoordinatorProvider).goComplete();
    } on Object catch (error, stackTrace) {
      if (!context.mounted) return;
      handleMinglitError(context, error, stackTrace);
    }
  }
}

class _PartnerDeletionGuardCard extends ConsumerWidget {
  const _PartnerDeletionGuardCard({
    required this.guardState,
  });

  final AsyncValue<PartnerAccountDeletionGuard> guardState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final coordinator = ref.read(accountDeletionCoordinatorProvider);

    return guardState.when(
      loading: () => const Card(
        child: ListTile(
          leading: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title: Text('탈퇴 가능 여부를 확인하고 있어요'),
          subtitle: Text('활성 이벤트, 정산, 환불 상태를 불러오는 중입니다.'),
        ),
      ),
      error: (error, stackTrace) => Card(
        color: MinglitColors.error.withValues(alpha: 0.08),
        child: const ListTile(
          leading: Icon(Icons.error_outline, color: MinglitColors.error),
          title: Text('탈퇴 가능 여부를 확인하지 못했어요'),
          subtitle: Text('잠시 후 다시 시도해주세요.'),
        ),
      ),
      data: (guard) {
        final items = <_BlockingItem>[
          if (guard.activeEventCount > 0)
            _BlockingItem(
              title: '활성 이벤트 ${guard.activeEventCount}건',
              description: '진행 예정 이벤트를 모두 종료하거나 정리해야 해요.',
              actionLabel: '이벤트 관리로 이동',
              onTap: coordinator.goToPartyList,
            ),
          if (guard.unsettledSettlementCount > 0)
            _BlockingItem(
              title: '미정산 건 ${guard.unsettledSettlementCount}건',
              description: '정산이 완료되거나 취소되어야 탈퇴를 요청할 수 있어요.',
              actionLabel: '정산 페이지로 이동',
              onTap: coordinator.goToSettlement,
            ),
          if (guard.pendingRefundCount > 0)
            _BlockingItem(
              title: '환불 대기 건 ${guard.pendingRefundCount}건',
              description: '환불 요청이 모두 처리된 뒤 탈퇴할 수 있어요.',
              actionLabel: '신청 관리로 이동',
              onTap: coordinator.goToApplications,
            ),
        ];

        if (items.isEmpty) {
          return Card(
            color: theme.colorScheme.primaryContainer,
            child: ListTile(
              leading: Icon(
                Icons.verified_outlined,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              title: Text(
                '탈퇴 요청을 진행할 수 있어요',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              subtitle: Text(
                '차단 조건이 없어 본인 확인 후 바로 요청할 수 있습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          );
        }

        return Card(
          color: MinglitColors.error.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '아래 항목을 먼저 정리해야 탈퇴할 수 있어요',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: MinglitColors.error,
                  ),
                ),
                const SizedBox(height: MinglitSpacing.small),
                for (final item in items) ...[
                  Text(item.title, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: MinglitSpacing.xsmall),
                  Text(item.description),
                  const SizedBox(height: MinglitSpacing.small),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: item.onTap,
                      child: Text(item.actionLabel),
                    ),
                  ),
                  if (item != items.last)
                    const Divider(height: MinglitSpacing.large),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BlockingItem {
  const _BlockingItem({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onTap;
}
