import 'package:app_user/src/features/auth/logic/auth_coordinator.dart';
import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    // 비로그인 상태: 로그인 유도 placeholder
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('마이페이지')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline,
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
                '로그인하고 나의 정보를 확인해보세요',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: MinglitSpacing.xlarge),
              FilledButton(
                onPressed: () {
                  ref.read(authCoordinatorProvider).pushLogin(from: '/my');
                },
                child: const Text('로그인'),
              ),
            ],
          ),
        ),
      );
    }

    final avatarUrl = user.userMetadata?['avatar_url'] as String?;
    final displayName = user.userMetadata?['full_name'] as String? ?? '유저';
    final homeCoordinator = ref.read(homeCoordinatorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
      ),
      body: ListView(
        children: [
          // 1. Profile Section
          Padding(
            padding: const EdgeInsets.all(MinglitSpacing.large),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? const Icon(Icons.person, size: 32)
                      : null,
                ),
                const SizedBox(width: MinglitSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // 2. Menu Items
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('구매 내역'),
            trailing: const Icon(Icons.chevron_right),
            onTap: homeCoordinator.pushPurchaseHistory,
          ),
          ListTile(
            leading: const Icon(Icons.confirmation_number_outlined),
            title: const Text('내 티켓'),
            trailing: const Icon(Icons.chevron_right),
            onTap: homeCoordinator.pushPurchaseHistory,
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('알림 설정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: homeCoordinator.pushNotificationSettings,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: MinglitColors.error),
            title: Text(
              '로그아웃',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(color: MinglitColors.error),
            ),
            onTap: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                ref.read(authCoordinatorProvider).goToLogin();
              }
            },
          ),
        ],
      ),
    );
  }
}
