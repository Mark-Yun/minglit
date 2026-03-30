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

          // 2. Menu Items — 거래
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
            // Fix #641: "내 티켓" → MyTicketsPage로 이동
            onTap: homeCoordinator.pushMyTickets,
          ),
          // Fix #187: 그룹별 구분선 추가 — 거래 / 앱 설정
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('알림 설정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: homeCoordinator.pushNotificationSettings,
          ),
          const ThemeSettingsTile(),
          // Fix #187: 그룹별 구분선 추가 — 앱 설정 / 개인정보·보안
          const Divider(),
          // Fix #139: Add privacy and permissions menu items
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('개인정보'),
            trailing: const Icon(Icons.chevron_right),
            // Fix #404: Use coordinator instead of direct route push
            onTap: homeCoordinator.pushPrivacy,
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined),
            title: const Text('권한 설정'),
            trailing: const Icon(Icons.chevron_right),
            // Fix #186: minglit_kit 공유 권한 설정 화면 사용
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
            // Fix #404: Use coordinator instead of direct route push
            onTap: homeCoordinator.pushBlockedPartners,
          ),
          // Dev-only: Design Catalog (hidden in production)
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
            leading: const Icon(Icons.logout, color: MinglitColors.error),
            title: Text(
              '로그아웃',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(color: MinglitColors.error),
            ),
            onTap: () async {
              // Fix #404: Use coordinator instead of direct GoRouter access
              // 먼저 홈으로 이동 후 signOut — /my (protected) 에서 signOut하면
              // GoRouter redirect가 /login으로 보내는 race condition 방지
              homeCoordinator.goToHome();
              // yield: 라우터가 위치를 '/' 로 업데이트한 뒤 signOut
              await Future<void>.delayed(Duration.zero);
              await ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
    );
  }
}
