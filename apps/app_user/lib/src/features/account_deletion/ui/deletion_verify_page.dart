import 'package:app_user/src/features/account_deletion/account_deletion_flow.dart';
import 'package:app_user/src/features/account_deletion/logic/account_deletion_coordinator.dart';
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
    final isLoading = deletionState.isLoading;
    final reason = buildWithdrawalReason(
      reasonCode: widget.reasonCode,
      reasonText: widget.reasonText,
    );

    if (user == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final isPasswordUser = usesPasswordAuth(user);

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
                    '회원 탈퇴 전에 본인 확인이 필요해요.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: MinglitSpacing.small),
                  Text(
                    '탈퇴 요청이 접수되면 7일 동안 복구할 수 있어요.',
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
                  onPressed: isLoading
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
        message: '탈퇴 요청 후 7일 동안은 다시 로그인해 복구할 수 있어요.',
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
