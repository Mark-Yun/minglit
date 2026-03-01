import 'package:app_user/src/features/auth/logic/auth_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// 비로그인 상태에서 보호된 페이지에 접근했을 때
/// 로그인 유도 화면을 보여주는 auth guard 위젯.
///
/// GoRouter redirect 대신 사용하여, 로그인 화면을 push로 쌓아
/// 백버튼이 이전 화면으로 자연스럽게 돌아가도록 함.
class AuthGuard extends ConsumerWidget {
  const AuthGuard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user != null) return child;

    final theme = Theme.of(context);
    final currentPath = GoRouterState.of(context).uri.toString();

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: MinglitSpacing.medium),
            Text(
              '로그인이 필요합니다',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: MinglitSpacing.small),
            Text(
              '이 페이지를 이용하려면 로그인해주세요',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: MinglitSpacing.xlarge),
            FilledButton(
              onPressed: () {
                ref.read(authCoordinatorProvider).pushLogin(from: currentPath);
              },
              child: const Text('로그인'),
            ),
          ],
        ),
      ),
    );
  }
}
