import 'package:flutter/material.dart';
import 'package:mds/mds.dart';

/// Shared account management page for app_user and app_partner.
///
/// Fix #1213: 계정 관리 서브페이지로 로그아웃/회원탈퇴 통합
// Fix #2121: MinglitSettingsGroup + MinglitSettingsTile 패턴으로 visual contract 통일
class AccountManagementPage extends StatelessWidget {
  const AccountManagementPage({
    required this.onLogout,
    required this.onDeleteAccount,
    super.key,
    this.onPartnerProfile,
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
    final hasProfileGroup = onCertification != null || onPartnerProfile != null;

    return Scaffold(
      backgroundColor: MinglitColors.surface,
      appBar: AppBar(
        title: const Text('계정 관리'),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.medium),
        child: Column(
          children: [
            if (hasProfileGroup) ...[
              MinglitSettingsGroup(
                children: [
                  // Fix #1861: 본인인증 진입점 — 계정에 귀속된 신원 속성
                  if (onCertification != null)
                    MinglitSettingsTile(
                      leading: isVerified
                          ? Icons.verified_user
                          : Icons.shield_outlined,
                      iconColor: isVerified ? MinglitColors.success : null,
                      title: '본인인증',
                      subtitle: isVerified ? '인증 완료' : '인증하기',
                      subtitleColor: isVerified ? MinglitColors.success : null,
                      onTap: onCertification,
                    ),
                  if (onPartnerProfile != null)
                    MinglitSettingsTile(
                      leading: Icons.store_outlined,
                      title: '파트너 프로필',
                      onTap: onPartnerProfile,
                    ),
                ],
              ),
              const SizedBox(height: MinglitSpacing.large),
            ],
            MinglitSettingsGroup(
              header: '계정 관리',
              children: [
                MinglitSettingsTile(
                  leading: Icons.logout,
                  title: '로그아웃',
                  trailing: SettingsTileTrailing.none,
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
                MinglitSettingsTile(
                  leading: Icons.person_remove_outlined,
                  title: '회원 탈퇴',
                  destructive: true,
                  trailing: SettingsTileTrailing.none,
                  onTap: onDeleteAccount,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
