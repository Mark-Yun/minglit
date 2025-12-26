import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:app_partner/main.dart'; 
import '../verification/review_verification_page.dart';

class PartnerDevMap extends StatelessWidget {
  const PartnerDevMap({super.key});

  @override
  Widget build(BuildContext context) {
    return DevScreenList(
      appName: 'Minglit Partner',
      items: [
        DevScreenItem(
          title: 'Main App Flow',
          description: '파트너 앱 정상 시작 흐름',
          screenBuilder: (_) => const AuthWrapper(),
        ),
        DevScreenItem(
          title: 'Partner Login',
          description: '파트너 전용 로그인 화면',
          screenBuilder: (_) => const PartnerLoginPage(),
        ),
        DevScreenItem(
          title: 'Partner Home',
          description: '파트너 대시보드 메인',
          screenBuilder: (_) => const PartnerHomePage(),
        ),
        DevScreenItem(
          title: 'Verification Review',
          description: '유저 인증 요청 심사 (승인/반려)',
          screenBuilder: (_) => const ReviewVerificationPage(),
        ),
        DevScreenItem(
          title: 'My Profile Preview',
          description: '내 파트너 정보 미리보기',
          screenBuilder: (_) => Scaffold(
            appBar: AppBar(title: const Text('My Profile')),
            body: PartnerDetailView(
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
