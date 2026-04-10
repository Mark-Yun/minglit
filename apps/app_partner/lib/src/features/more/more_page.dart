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

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '더보기'),
      body: ListView(
        children: [
          partnerAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(MinglitSpacing.large),
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => Padding(
              padding: const EdgeInsets.all(MinglitSpacing.large),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    child: Icon(Icons.store, size: 32),
                  ),
                  const SizedBox(width: MinglitSpacing.medium),
                  Expanded(
                    child: Text(
                      '파트너 정보를 불러올 수 없습니다',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            data: (partner) {
              if (partner == null) {
                return Padding(
                  padding: const EdgeInsets.all(MinglitSpacing.large),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 32,
                        child: Icon(Icons.store, size: 32),
                      ),
                      const SizedBox(width: MinglitSpacing.medium),
                      Expanded(
                        child: Text(
                          '파트너 정보를 불러올 수 없습니다',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.all(MinglitSpacing.large),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: partner.profileImageUrl != null
                          ? NetworkImage(partner.profileImageUrl!)
                          : null,
                      child: partner.profileImageUrl == null
                          ? const Icon(Icons.store, size: 32)
                          : null,
                    ),
                    const SizedBox(width: MinglitSpacing.medium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            partner.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (partner.contactEmail != null)
                            Text(
                              partner.contactEmail!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('인증 심사 관리'),
            onTap: moreCoordinator.pushVerificationManage,
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('멤버 관리'),
            onTap: () {
              final partner = partnerAsync.value;
              if (partner == null) {
                context.showMinglitInfo('파트너 정보를 불러오는 중입니다');
                return;
              }
              moreCoordinator.pushMemberList(partner.id);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('알림 설정'),
            onTap: moreCoordinator.pushNotificationSettings,
          ),
          const ThemeSettingsTile(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.manage_accounts_outlined),
            title: const Text('계정 관리'),
            trailing: const Icon(Icons.chevron_right),
            onTap: moreCoordinator.pushAccountManagement,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('개인정보처리방침'),
            onTap: () {
              final url = ref.read(minglitUrlConfigProvider).privacyUrl;
              unawaited(launchUrl(Uri.parse(url)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('이용약관'),
            onTap: () {
              final url = ref.read(minglitUrlConfigProvider).termsUrl;
              unawaited(launchUrl(Uri.parse(url)));
            },
          ),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '-';
              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('앱 버전'),
                trailing: Text(
                  version,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
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
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const DesignCatalogPage(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
