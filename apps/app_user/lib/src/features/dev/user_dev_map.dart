import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import '../../main.dart'; // AuthWrapper 등을 위해
import '../verification/verification_page.dart';
import '../verification/career_verification_form.dart';
import '../verification/verification_inbox_page.dart';

class UserDevMap extends StatelessWidget {
  const UserDevMap({super.key});

  @override
  Widget build(BuildContext context) {
    return DevScreenList(
      appName: 'Minglit User',
      items: [
        DevScreenItem(
          title: 'Main App Flow',
          description: '정상적인 앱 시작 흐름 (인증 체크)',
          screenBuilder: (_) => const AuthWrapper(),
        ),
        DevScreenItem(
          title: 'Login Page',
          description: '로그인 및 소셜 가입 화면',
          screenBuilder: (_) => const LoginPage(),
        ),
        DevScreenItem(
          title: 'Home Page',
          description: '로그인 후 메인 홈 화면',
          screenBuilder: (_) => const HomePage(),
        ),
        DevScreenItem(
          title: 'Verification Management',
          description: '다중 인증 및 보완 요청 관리 페이지',
          screenBuilder: (_) {
            return const VerificationManagementPage(
              partnerId: '00000000-0000-0000-0000-000000000000', // 테스트용 더미 ID
              requiredVerificationIds: [], 
            );
          },
        ),
        DevScreenItem(
          title: 'Verification Inbox',
          description: '보완 요청 알림 리스트',
          screenBuilder: (_) => const VerificationInboxPage(),
        ),
      ],
    );
  }
}
