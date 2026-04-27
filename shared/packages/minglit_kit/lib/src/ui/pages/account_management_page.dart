import 'package:flutter/material.dart';
import 'package:mds/src/theme/minglit_theme.dart';
import 'package:mds/src/ui/widgets/common/minglit_alert.dart';

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
    // Fix #1861: 본인인증 진입점 — null이면 타일 숨김 (app_partner)
    this.onCertification,
    this.isVerified = false,
  });

  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  /// Optional partner profile callback. When non-null, shows a partner profile
  /// tile at the top of the page (app_partner only).
  final VoidCallback? onPartnerProfile;

  /// Optional certification callback. When non-null, shows an identity
  /// verification tile (app_user only). Null hides the tile.
  final VoidCallback? onCertification;

  /// Whether the user has completed identity verification.
  /// Only meaningful when [onCertification] is non-null.
  final bool isVerified;

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
          // Fix #1861: 본인인증 진입점 — 계정에 귀속된 신원 속성
          if (onCertification != null) ...[
            ListTile(
              leading: Icon(
                isVerified ? Icons.verified_user : Icons.shield_outlined,
                color: isVerified ? MinglitColors.success : null,
              ),
              title: const Text('본인인증'),
              subtitle: Text(
                isVerified ? '인증 완료' : '인증하기',
                style: TextStyle(
                  color: isVerified
                      ? MinglitColors.success
                      : MinglitColors.textSecondary,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: onCertification,
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
                    // Fix #1378: 로그아웃 즉시 실행 방지 — 확인 다이얼로그 추가
                    onTap: () async {
                      final confirmed = await MinglitAlert.showConfirm(
                        context: context,
                        title: '로그아웃',
                        content: '로그아웃 하시겠어요?',
                        confirmText: '로그아웃',
                      );
                      if (confirmed) onLogout();
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
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
