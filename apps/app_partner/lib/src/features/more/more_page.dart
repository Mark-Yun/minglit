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

    final permissions =
        ref.watch(currentMemberPermissionsProvider).asData?.value ?? [];
    final canEditSettlement = permissions.contains('SETTLEMENT_EDIT');

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
            error: (error, stackTrace) => const MinglitSettingsGroup(
              children: [
                // onTap: null — 에러 상태에서는 타일 비활성화
                _ProfileTile(
                  displayName: '정보를 불러올 수 없습니다',
                  email: '',
                ),
              ],
            ),
            data: (partner) {
              if (partner == null) {
                return const MinglitSettingsGroup(
                  children: [
                    // onTap: null — 파트너 없음 상태에서는 타일 비활성화
                    _ProfileTile(
                      displayName: '파트너 정보를 불러올 수 없습니다',
                      email: '',
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
              if (canEditSettlement)
                MinglitSettingsTile(
                  leading: Icons.account_balance_wallet_outlined,
                  title: '정산 계좌 관리',
                  onTap: moreCoordinator.pushBankAccountManagement,
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

          // Dev Only — Fix #1624: 'dev' 추가 (Supabase dev 프로젝트와 정합성)
          if (const String.fromEnvironment(
                    'ENVIRONMENT',
                    defaultValue: 'production',
                  ) ==
                  'local' ||
              const String.fromEnvironment(
                    'ENVIRONMENT',
                    defaultValue: 'production',
                  ) ==
                  'development' ||
              const String.fromEnvironment(
                    'ENVIRONMENT',
                    defaultValue: 'production',
                  ) ==
                  'dev') ...[
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

          // Fix #1803: SafeArea prevents last item overlap with gesture nav bar
          const SafeArea(
            top: false,
            child: SizedBox(height: MinglitSpacing.xxlarge),
          ),
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
                  // email이 비어있는 에러/널 상태에서는 서브타이틀 숨김
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            // 비활성 상태에서는 chevron 숨김
            if (onTap != null)
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
