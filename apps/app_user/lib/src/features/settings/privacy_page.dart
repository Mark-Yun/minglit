import 'package:app_user/src/features/account_deletion/logic/account_deletion_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PrivacyPage extends ConsumerWidget {
  /// Creates a [PrivacyPage].
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final deletionStatus = ref.watch(accountDeletionControllerProvider);
    final isPending = deletionStatus.value?.isPending ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('개인정보')),
      body: ListView(
        padding: const EdgeInsets.all(MinglitSpacing.large),
        children: [
          Icon(
            Icons.lock_outline,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: MinglitSpacing.medium),
          Text(
            '개인정보 관리',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: MinglitSpacing.small),
          Text(
            '회원 탈퇴 요청을 진행하면 7일 동안 다시 로그인해 계정을 복구할 수 있어요.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),
          Card(
            child: ListTile(
              leading: Icon(
                isPending ? Icons.hourglass_top : Icons.person_remove_outlined,
                color: MinglitColors.error,
              ),
              title: Text(isPending ? '탈퇴 요청 진행 중' : '회원 탈퇴'),
              subtitle: Text(
                isPending
                    ? '유예 기간 안에는 다시 로그인해 계정을 복구할 수 있어요.'
                    : '탈퇴 사유 선택, 안내 확인, 본인 확인 후 요청할 수 있어요.',
              ),
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                ref.read(accountDeletionCoordinatorProvider).start();
              },
              child: Text(isPending ? '탈퇴 진행 상태 보기' : '회원 탈퇴 시작하기'),
            ),
          ),
        ],
      ),
    );
  }
}
