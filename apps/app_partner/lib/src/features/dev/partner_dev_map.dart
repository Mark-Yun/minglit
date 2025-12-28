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
          title: 'Login Page',
          description: '로그인 화면',
          screenBuilder: (_) => const PartnerLoginPage(),
        ),
        DevScreenItem(
          title: 'Home Page',
          description: '메인 대시보드',
          screenBuilder: (_) => const PartnerHomePage(),
        ),

        DevScreenItem(
          title: 'Verification Review',
          description: '유저 인증 요청 심사 (승인/반려)',
          screenBuilder: (_) => const ReviewVerificationPage(),
        ),
        DevScreenItem(
          title: 'Admin: Partner Applications',
          description: '관리자: 파트너 입점 신청 목록 심사',
          screenBuilder: (_) => const PartnerApplicationListPage(),
        ),
        DevScreenItem(
          title: 'Application Detail',
          description: '입점 신청 상세 화면',
          screenBuilder:
              (_) =>
                  const PartnerApplicationDetailPage(applicationId: 'dummy-id'),
        ),

        DevScreenItem(
          title: 'My Profile Preview',
          description: '내 파트너 정보 미리보기',
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
