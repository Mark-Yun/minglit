import 'package:app_user/src/features/auth/logic/auth_coordinator.dart';
import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_dev.dart';
import 'package:minglit_kit/minglit_kit.dart';

class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

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
              Text('로그인이 필요합니다', style: theme.textTheme.titleMedium),
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

    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          homeCoordinator.goToHome();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('마이페이지')),
        body: ListView(
          children: [
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
              onTap: homeCoordinator.pushMyTickets,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('알림 설정'),
              trailing: const Icon(Icons.chevron_right),
              onTap: homeCoordinator.pushNotificationSettings,
            ),
            const ThemeSettingsTile(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('개인정보'),
              trailing: const Icon(Icons.chevron_right),
              onTap: homeCoordinator.pushPrivacy,
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('권한 설정'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const AppPermissionSettingsScreen(),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('차단 목록'),
              trailing: const Icon(Icons.chevron_right),
              onTap: homeCoordinator.pushBlockedPartners,
            ),
            if (const String.fromEnvironment(
                      'ENVIRONMENT',
                      defaultValue: 'production',
                    ) ==
                    'local' ||
                const String.fromEnvironment(
                      'ENVIRONMENT',
                      defaultValue: 'production',
                    ) ==
                    'development') ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Design Catalog'),
                subtitle: const Text('Dev Only'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const DesignCatalogPage(),
                  ),
                ),
              ),
            ],
            const Divider(),
            ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text('계정 관리'),
              trailing: const Icon(Icons.chevron_right),
              onTap: homeCoordinator.pushAccountManagement,
            ),
          ],
        ),
      ),
    );
  }
}
