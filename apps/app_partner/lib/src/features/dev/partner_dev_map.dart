import 'package:app_partner/src/features/admin/partner_application_detail_page.dart';
import 'package:app_partner/src/features/admin/partner_application_list_page.dart';
import 'package:app_partner/src/features/auth/partner_login_page.dart';
import 'package:app_partner/src/features/home/partner_home_page.dart';
import 'package:app_partner/src/features/verification/review_verification_page.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartnerDevMap extends StatelessWidget {
  const PartnerDevMap({super.key});

  @override
  Widget build(BuildContext context) {
    return DevScreenList(
      appName: 'Minglit Partner',
      items: [
        DevScreenItem(
          category: 'Auth',
          title: 'Login',
          description: '파트너 로그인 화면',
          screenBuilder: (_) => const PartnerLoginPage(),
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
          screenBuilder:
              (_) =>
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
          title: 'My Partner Profile',
          description: '유저에게 노출되는 파트너 프로필 미리보기',
          screenBuilder:
              (_) => Scaffold(
                appBar: AppBar(title: const Text('My Profile')),
                body: const PartnerDetailView(
                  partner: Partner(
                    id: 'my-id',
                    name: '밍글릿 사장님 모드',
                    introduction: '파트너 앱에서 설정한 정보가 유저들에게 이렇게 보입니다.',
                    bizName: '성공하는 파트너',
                    representativeName: '김대표',
                    bizNumber: '987-65-43210',
                    contactEmail: 'partner@minglit.com',
                  ),
                ),
              ),
        ),
      ],
    );
  }
}
