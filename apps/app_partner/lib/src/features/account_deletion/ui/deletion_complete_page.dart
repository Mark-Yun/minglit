import 'package:app_partner/src/features/account_deletion/account_deletion_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class DeletionCompletePage extends ConsumerWidget {
  const DeletionCompletePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('탈퇴 완료')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MinglitSpacing.large),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                Icons.check_circle_rounded,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: MinglitSpacing.large),
              Text(
                '탈퇴 요청이 완료됐어요',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: MinglitSpacing.small),
              Text(
                '지금부터 7일 안에 다시 로그인하면 계정을 복구할 수 있어요.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _finish(context, ref),
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    ref.read(accountDeletionCoordinatorProvider).goToHome();
    await Future<void>.delayed(Duration.zero);
    await ref.read(authControllerProvider.notifier).signOut();
    if (!context.mounted) return;
    context.showMinglitSuccess('탈퇴 요청이 접수되었어요.');
  }
}
