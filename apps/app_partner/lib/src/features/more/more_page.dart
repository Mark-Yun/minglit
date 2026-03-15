import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('더보기')),
      body: ListView(
        children: [
          // Profile Section
          if (user != null)
            Padding(
              padding: const EdgeInsets.all(MinglitSpacing.large),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: user.userMetadata?['avatar_url'] != null
                        ? NetworkImage(
                            user.userMetadata!['avatar_url'] as String,
                          )
                        : null,
                    child: user.userMetadata?['avatar_url'] == null
                        ? const Icon(Icons.person, size: 32)
                        : null,
                  ),
                  const SizedBox(width: MinglitSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.userMetadata?['full_name'] as String? ?? '파트너',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (user.email != null) ...[
                          const SizedBox(height: MinglitSpacing.small),
                          Text(
                            user.email!,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: MinglitColors.textSecondary,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(MinglitSpacing.large),
              child: Text('로그인이 필요합니다.'),
            ),
          const Divider(),

          // Section 1 (관리)
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('멤버 관리'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO(partner): navigate to MemberListRoute with partnerId
            },
          ),
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: const Text('본인인증 관리'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO(partner): navigate to VerificationManageRoute
            },
          ),
          const Divider(),

          // Section 2 (설정)
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('알림 설정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO(partner): navigate to notification settings
            },
          ),
          const ThemeSettingsTile(),
          const Divider(),

          // Section 3 (앱 정보)
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('권한'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final url = Uri.parse('app-settings:');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('개인정보처리방침'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final url = Uri.parse('https://minglit.com/privacy');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('이용약관'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final url = Uri.parse('https://minglit.com/terms');
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
          ),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.hasData ? snapshot.data!.version : '';
              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('앱 버전'),
                trailing: Text(version),
              );
            },
          ),
          const Divider(),

          // Section 4 (계정)
          ListTile(
            leading: const Icon(Icons.logout, color: MinglitColors.error),
            title: const Text(
              '로그아웃',
              style: TextStyle(color: MinglitColors.error),
            ),
            onTap: () {
              unawaited(ref.read(authControllerProvider.notifier).signOut());
              GoRouter.of(context).go('/');
            },
          ),
        ],
      ),
    );
  }
}
