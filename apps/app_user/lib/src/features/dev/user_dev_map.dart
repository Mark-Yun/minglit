import 'package:app_user/src/features/auth/auth_wrapper.dart';
import 'package:app_user/src/features/auth/login_page.dart';
import 'package:app_user/src/features/home/home_page.dart';
import 'package:app_user/src/features/verification/verification_inbox_page.dart';
import 'package:app_user/src/features/verification/verification_page.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class UserDevMap extends StatelessWidget {
  const UserDevMap({super.key});

  @override
  Widget build(BuildContext context) {
    return DevScreenList(
      appName: 'Minglit User',
      items: [
        DevScreenItem(
          category: 'App Flow',
          title: 'App Entry (Auth Wrapper)',
          description: '인증 상태에 따른 자동 분기 흐름',
          screenBuilder: (_) => const AuthWrapper(),
        ),
        DevScreenItem(
          category: 'Auth',
          title: 'Login',
          description: '로그인 및 소셜 가입 화면',
          screenBuilder: (_) => const LoginPage(),
        ),
        DevScreenItem(
          category: 'Auth',
          title: 'Session Switcher',
          description: '테스트 유저 계정으로 즉시 전환',
          screenBuilder: (_) => const DevUserSwitchScreen(),
        ),
        DevScreenItem(
          category: 'Home',
          title: 'Home',
          description: '메인 홈 화면 (파티 목록 등)',
          screenBuilder: (_) => const HomePage(),
        ),
        DevScreenItem(
          category: 'Verification',
          title: 'Verification Center',
          description: '인증 진행 현황 및 관리',
          screenBuilder: (_) {
            return const VerificationManagementPage(
              partnerId: '00000000-0000-0000-0000-000000000000',
              requiredVerificationIds: [],
            );
          },
        ),
        DevScreenItem(
          category: 'Verification',
          title: 'Verification Inbox',
          description: '인증 관련 알림 및 메시지 함',
          screenBuilder: (_) => const VerificationInboxPage(),
        ),
        DevScreenItem(
          category: 'Preview',
          title: 'Partner List Preview',
          description: '생성된 모든 파트너 목록 및 상세 화면 확인',
          screenBuilder: (_) => const PartnerListPreviewScreen(),
        ),
      ],
    );
  }
}
