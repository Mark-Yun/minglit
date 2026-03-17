import 'dart:async';
import 'package:app_partner/src/features/more/more_coordinator.dart';
import 'package:app_partner/src/features/party/party_providers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnerAsync = ref.watch(currentPartnerInfoProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '더보기'),
      body: ListView(
        children: [
          // ── 프로필 헤더 ──
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
                  Text(
                    '파트너 정보를 불러올 수 없습니다',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
                      Text(
                        '파트너 정보를 불러올 수 없습니다',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
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

          // ── 섹션 1: 관리 ──
          // Fix #144: trailing chevron icons removed for cleaner settings UI
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('인증 심사 관리'),
            onTap: () =>
                ref.read(moreCoordinatorProvider).pushVerificationManage(),
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
              ref.read(moreCoordinatorProvider).pushMemberList(partner.id);
            },
          ),
          const Divider(),

          // ── 섹션 2: 설정 ──
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('알림 설정'),
            onTap: () =>
                ref.read(moreCoordinatorProvider).pushNotificationSettings(),
          ),
          const ThemeSettingsTile(),
          const Divider(),

          // ── 섹션 3: 계정 (비활성) ──
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('계정 관리'),
            onTap: () => context.showMinglitInfo('준비 중입니다'),
          ),
          ListTile(
            leading: const Icon(Icons.store_outlined),
            title: const Text('파트너 프로필'),
            onTap: () => context.showMinglitInfo('준비 중입니다'),
          ),
          const Divider(),

          // ── 섹션 4: 앱 정보 ──
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
          const Divider(),

          // ── 섹션 5: 로그아웃 ──
          ListTile(
            leading: const Icon(Icons.logout, color: MinglitColors.error),
            title: Text(
              '로그아웃',
              style: theme.textTheme.bodyMedium!.copyWith(
                color: MinglitColors.error,
              ),
            ),
            onTap: () async {
              // GoRouter-first 패턴: '/' 이동 후 signOut — race condition 방지
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
