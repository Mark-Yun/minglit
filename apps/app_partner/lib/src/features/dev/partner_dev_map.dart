import 'package:app_partner/src/features/admin/partner_application_detail_page.dart';
import 'package:app_partner/src/features/admin/partner_application_list_page.dart';
import 'package:app_partner/src/features/auth/partner_login_page.dart';
import 'package:app_partner/src/features/home/partner_home_page.dart';
import 'package:app_partner/src/features/party/create/party_create_screen.dart';
import 'package:app_partner/src/features/verification/create_verification_screen.dart';
import 'package:app_partner/src/features/verification/review_verification_page.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartnerDevMap extends StatelessWidget {
  const PartnerDevMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DevScreenList(
        appName: 'Minglit Partner',
        items: [
          DevScreenItem(
            category: 'Party',
            title: 'Create Party',
            description: '새로운 파티 생성',
            screenBuilder: (_) => const PartyCreateScreen(),
          ),
          DevScreenItem(
            category: 'Verification',
            title: 'Create Verification',
            description: '새로운 인증 요구사항 생성 (커스텀 폼)',
            screenBuilder: (_) => const CreateVerificationScreen(),
          ),
          DevScreenItem(
            category: 'Auth',
            title: 'Login',
            description: '파트너 로그인 화면',
            screenBuilder: (_) => const PartnerLoginPage(),
          ),
          DevScreenItem(
            category: 'Auth',
            title: 'Session Switcher',
            description: '테스트 유저 계정으로 즉시 전환',
            screenBuilder: (_) => const DevUserSwitchScreen(),
          ),
          DevScreenItem(
            category: 'Dashboard',
            title: 'Main Dashboard',
            description: '메인 관리 대시보드',
            screenBuilder: (_) => const PartnerHomePage(),
          ),
          DevScreenItem(
            category: 'Admin',
            title: 'Application List',
            description: '파트너 입점 신청 목록 (관리자)',
            screenBuilder: (_) => const PartnerApplicationListPage(),
          ),
          DevScreenItem(
            category: 'Admin',
            title: 'Application Detail',
            description: '입점 신청 상세 정보 및 심사',
            screenBuilder: (_) =>
                const PartnerApplicationDetailPage(applicationId: 'dummy-id'),
          ),
          DevScreenItem(
            category: 'Verification',
            title: 'User Verifications',
            description: '사용자 인증(PASS/재직) 요청 심사',
            screenBuilder: (_) => const ReviewVerificationPage(),
          ),
          DevScreenItem(
            category: 'Preview',
            title: 'Partner List Preview',
            description:
                '생성된 모든 파트너 목록 및 '
                '상세 화면 확인',
            screenBuilder: (_) => const PartnerListPreviewScreen(),
          ),
          DevScreenItem(
            category: 'Preview',
            title: 'Party List Preview',
            description: '생성된 모든 파티 목록 확인',
            screenBuilder: (_) => const PartyListPreviewScreen(),
          ),
          DevScreenItem(
            category: 'System',
            title: 'Global Loading Test',
            description: '3초간 전역 로딩 오버레이 테스트',
            onTap: (context, ref) async {
              final notifier = ref.read(
                globalLoadingControllerProvider.notifier,
              )..show();
              await Future<void>.delayed(const Duration(seconds: 3));
              notifier.hide();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigation result is not used
          // ignore: discarded_futures
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const DevUserSwitchScreen(),
            ),
          );
        },
        child: const Icon(Icons.people_alt),
      ),
    );
  }
}
