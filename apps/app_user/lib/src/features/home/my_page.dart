import 'package:app_user/src/features/auth/logic/auth_coordinator.dart';
import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:app_user/src/features/settings/blocked_partners_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
          // Profile Section
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

          // Section 1: 활동
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
          const Divider(),

          // Section 2: 설정
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('알림 설정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: homeCoordinator.pushNotificationSettings,
          ),
          const ThemeSettingsTile(),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('차단 목록'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const BlockedPartnersPage(),
              ),
            ),
          ),
          const Divider(),

          // Section 3: 앱 정보
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('권한'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => launchUrl(Uri.parse('app-settings:')),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('개인정보처리방침'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => launchUrl(Uri.parse('https://minglit.com/privacy')),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('이용약관'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => launchUrl(Uri.parse('https://minglit.com/terms')),
          ),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('앱 버전'),
                trailing: snapshot.hasData
                    ? Text(
                        '${snapshot.data!.version}'
                        '+${snapshot.data!.buildNumber}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : null,
              );
            },
          ),
          const Divider(),

          // Section 4: 계정
          ListTile(
            leading: const Icon(Icons.logout, color: MinglitColors.error),
            title: Text(
              '로그아웃',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(color: MinglitColors.error),
            ),
            onTap: () async {
              GoRouter.of(context).go('/');
              await Future<void>.delayed(Duration.zero);
              await ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
    );
  }
}
