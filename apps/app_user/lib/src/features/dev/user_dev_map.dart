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
          title: 'Partner Profile',
          description: '유저가 보는 파트너 상세 페이지 미리보기',
          screenBuilder:
              (_) => Scaffold(
                appBar: AppBar(title: const Text('Partner Profile')),
                body: const PartnerDetailView(
                  partner: Partner(
                    id: 'dummy-id',
                    name: '밍글릿 강남점',
                    introduction:
                        '강남 최고의 소셜 파티 공간, 밍글릿입니다. \n다양한 사람들과 즐거운 시간을 가져보세요!',
                    address: '서울시 강남구 테헤란로 123',
                    bizName: '(주)밍글릿 컴퍼니',
                    representativeName: '홍길동',
                    bizNumber: '123-45-67890',
                    contactEmail: 'contact@minglit.com',
                    contactPhone: '02-1234-5678',
                  ),
                ),
              ),
        ),
      ],
    );
  }
}
