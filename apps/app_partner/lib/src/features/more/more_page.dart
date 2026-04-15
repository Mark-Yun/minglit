import 'dart:async';

import 'package:app_partner/src/features/more/more_coordinator.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_dev.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnerAsync = ref.watch(currentPartnerInfoProvider);
    final moreCoordinator = ref.read(moreCoordinatorProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '더보기', showBackButton: false),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.medium),
        children: [
          // Group 1: Profile
          partnerAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(MinglitSpacing.large),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => MinglitSettingsGroup(
              children: [
                _ProfileTile(
                  displayName: '정보를 불러올 수 없습니다',
                  email: '',
                  onTap: () {},
                ),
              ],
            ),
            data: (partner) {
              if (partner == null) {
                return MinglitSettingsGroup(
                  children: [
                    _ProfileTile(
                      displayName: '파트너 정보 없음',
                      email: '',
                      onTap: () {},
                    ),
                  ],
                );
              }
              return MinglitSettingsGroup(
                children: [
                  _ProfileTile(
                    displayName: partner.name,
                    email: partner.contactEmail ?? '',
                    avatarUrl: partner.profileImageUrl,
                    onTap: moreCoordinator.pushAccountManagement,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: MinglitSpacing.large),

          // Group 2: Business Management
          MinglitSettingsGroup(
            header: '비즈니스 관리',
            children: [
              MinglitSettingsTile(
                leading: Icons.event_note_outlined,
                title: '파티 관리',
                onTap: moreCoordinator.pushPartyList,
              ),
              MinglitSettingsTile(
                leading: Icons.verified_user_outlined,
                title: '인증 심사 관리',
                onTap: moreCoordinator.pushVerificationManage,
              ),
              MinglitSettingsTile(
                leading: Icons.people_outline,
                title: '멤버 관리',
                onTap: () {
                  final partner = partnerAsync.value;
                  if (partner == null) {
                    context.showMinglitInfo('파트너 정보를 불러오는 중입니다');
                    return;
                  }
                  moreCoordinator.pushMemberList(partner.id);
                },
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
                onTap: moreCoordinator.pushNotificationSettings,
              ),
              const ThemeSettingsTile(),
            ],
          ),
          const SizedBox(height: MinglitSpacing.large),

          // Group 4: Account
          MinglitSettingsGroup(
            header: '계정',
            children: [
              MinglitSettingsTile(
                leading: Icons.manage_accounts_outlined,
                title: '계정 관리',
                onTap: moreCoordinator.pushAccountManagement,
              ),
              MinglitSettingsTile(
                leading: Icons.logout_outlined,
                title: '로그아웃',
                destructive: true,
                trailing: SettingsTileTrailing.none,
                onTap: () async {
                  final confirmed = await MinglitAlert.showConfirm(
                    context,
                    title: '로그아웃',
                    message: '정말 로그아웃 하시겠습니까?',
                    confirmText: '로그아웃',
                    isDestructive: true,
                  );
                  if (confirmed) {
                    // Assuming there's a signOut in moreCoordinator or similar
                    // For now, reuse account management's signout if available
                    // or just a placeholder if not.
                    // Actually, app_partner should have its own auth logic.
                    // Let's check how logout is handled normally.
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: MinglitSpacing.large),

          // Group 5: Terms & Info
          MinglitSettingsGroup(
            header: '약관 및 정보',
            children: [
              MinglitSettingsTile(
                leading: Icons.privacy_tip_outlined,
                title: '개인정보처리방침',
                onTap: () {
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
                  final version = snapshot.data?.version ?? '26.04.1455';
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

          // Dev Only
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
            const SizedBox(height: MinglitSpacing.large),
            MinglitSettingsGroup(
              header: '개발자 도구',
              children: [
                MinglitSettingsTile(
                  leading: Icons.palette_outlined,
                  title: 'Design Catalog',
                  subtitle: 'Dev Only',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const DesignCatalogPage(),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: MinglitSpacing.xxlarge),
        ],
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
            CircleAvatar(
              radius: 24,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null
                  ? Icon(Icons.store, color: colorScheme.primary)
                  : null,
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
