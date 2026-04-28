import 'dart:async';

import 'package:app_user/src/common/widgets/minglit_avatar_image.dart';
import 'package:app_user/src/features/auth/logic/auth_coordinator.dart';
import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(
        appBar: MinglitTheme.simpleAppBar(
          title: '마이페이지',
          showBackButton: false,
        ),
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
              MinglitButton(
                label: '로그인',
                onPressed: () {
                  ref.read(authCoordinatorProvider).pushLogin(from: '/my');
                },
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
        appBar: MinglitTheme.simpleAppBar(
          title: '마이페이지',
          showBackButton: false,
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.medium),
          children: [
            // Group 1: Profile
            MinglitSettingsGroup(
              children: [
                _ProfileTile(
                  displayName: displayName,
                  email: user.email ?? '',
                  avatarUrl: avatarUrl,
                  onTap: homeCoordinator.pushAccountManagement,
                ),
              ],
            ),
            const SizedBox(height: MinglitSpacing.large),

            // Group 2: Activity
            MinglitSettingsGroup(
              header: '활동',
              children: [
                MinglitSettingsTile(
                  leading: Icons.receipt_long_outlined,
                  title: '구매 내역',
                  onTap: homeCoordinator.pushPurchaseHistory,
                ),
                MinglitSettingsTile(
                  leading: Icons.confirmation_number_outlined,
                  title: '내 티켓',
                  onTap: homeCoordinator.pushMyTickets,
                ),
              ],
            ),
            const SizedBox(height: MinglitSpacing.large),

            // Group 3: Settings
            MinglitSettingsGroup(
              header: '설정',
              children: [
                MinglitSettingsTile(
                  leading: Icons.notifications_outlined,
                  title: '알림 설정',
                  onTap: homeCoordinator.pushNotificationSettings,
                ),
                const ThemeSettingsTile(),
              ],
            ),
            const SizedBox(height: MinglitSpacing.large),

            // Group 4: Privacy & Security
            MinglitSettingsGroup(
              header: '개인정보 및 보안',
              children: [
                MinglitSettingsTile(
                  leading: Icons.lock_outline,
                  title: '개인정보',
                  onTap: homeCoordinator.pushPrivacy,
                ),
                MinglitSettingsTile(
                  leading: Icons.admin_panel_settings_outlined,
                  title: '권한 설정',
                  onTap: () =>
                      homeCoordinator.navigateToPermissionSettings(context),
                ),
                MinglitSettingsTile(
                  leading: Icons.block,
                  title: '차단 목록',
                  onTap: homeCoordinator.pushBlockedPartners,
                ),
              ],
            ),
            const SizedBox(height: MinglitSpacing.large),

            // Group 5: Terms & Info
            MinglitSettingsGroup(
              header: '약관 및 정보',
              children: [
                MinglitSettingsTile(
                  leading: Icons.shield_outlined,
                  title: '개인정보처리방침',
                  onTap: () {
                    // Fix #1939: '개인정보처리방침'은 동의 화면이 아닌 외부 개인정보처리방침 URL로 이동해야 함
                    final url = ref.read(minglitUrlConfigProvider).privacyUrl;
                    unawaited(launchUrl(Uri.parse(url)));
                  },
                ),
                MinglitSettingsTile(
                  leading: Icons.description_outlined,
                  title: '이용약관',
                  onTap: () {
                    final url = ref.read(minglitUrlConfigProvider).termsUrl;
                    unawaited(launchUrl(Uri.parse(url)));
                  },
                ),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.data?.version ?? '—';
                    return MinglitSettingsTile(
                      leading: Icons.info_outline,
                      title: '앱 버전',
                      subtitle: version,
                      trailing: SettingsTileTrailing.none,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: MinglitSpacing.large),

            // Group 6: Account
            MinglitSettingsGroup(
              header: '계정',
              children: [
                MinglitSettingsTile(
                  leading: Icons.manage_accounts_outlined,
                  title: '계정 관리',
                  onTap: homeCoordinator.pushAccountManagement,
                ),
                MinglitSettingsTile(
                  leading: Icons.logout_outlined,
                  title: '로그아웃',
                  destructive: true,
                  trailing: SettingsTileTrailing.none,
                  onTap: () async {
                    final confirmed = await MinglitAlert.showConfirm(
                      context: context,
                      title: '로그아웃',
                      content: '정말 로그아웃 하시겠습니까?',
                      confirmText: '로그아웃',
                      isDestructive: true,
                    );
                    if (confirmed) {
                      unawaited(
                        ref.read(authControllerProvider.notifier).signOut(),
                      );
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: MinglitSpacing.xxlarge),
          ],
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.onTap,
  });

  final String displayName;
  final String email;
  final String? avatarUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Row(
          children: [
            // Fix #1936: MinglitAvatarImage handles caching + error fallback
            MinglitAvatarImage(
              radius: 24,
              url: avatarUrl,
              backgroundColor: colorScheme.primaryContainer,
              fallbackIconColor: colorScheme.primary,
            ),
            const SizedBox(width: MinglitSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: MinglitIconSize.small,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
