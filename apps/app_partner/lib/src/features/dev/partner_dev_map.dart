import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import '../../main.dart'; 
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
      ],
    );
  }
}
