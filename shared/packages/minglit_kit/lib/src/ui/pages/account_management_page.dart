import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_design_tokens.dart';

/// Shared account management page for app_user and app_partner.
///
/// Consolidates logout and account deletion into a single sub-settings page.
/// Callbacks let each app inject its own logout/deletion logic.
///
/// Fix #1213: 계정 관리 서브페이지로 로그아웃/회원탈퇴 통합
class AccountManagementPage extends StatelessWidget {
  const AccountManagementPage({
    required this.onLogout,
    required this.onDeleteAccount,
    super.key,
    this.onPartnerProfile, // app_partner only — null hides the tile
  });

  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  /// Optional partner profile callback. When non-null, shows a partner profile
  /// tile at the top of the page (app_partner only).
  final VoidCallback? onPartnerProfile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('계정 관리')),
      body: ListView(
        children: [
          if (onPartnerProfile != null) ...[
            ListTile(
              leading: const Icon(Icons.store_outlined),
              title: const Text('파트너 프로필'),
              trailing: const Icon(Icons.chevron_right),
              onTap: onPartnerProfile,
            ),
            const Divider(),
          ],
          const SizedBox(height: 16),
          // Danger Zone
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: MinglitColors.error.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('로그아웃'),
                    onTap: onLogout,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.person_remove_outlined,
                      color: MinglitColors.error,
                    ),
                    title: const Text(
                      '회원 탈퇴',
                      style: TextStyle(color: MinglitColors.error),
                    ),
                    onTap: onDeleteAccount,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
