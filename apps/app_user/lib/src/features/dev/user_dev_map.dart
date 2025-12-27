import 'package:app_user/main.dart'; // 패키지 임포트로 변경
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
        DevScreenItem(
          title: 'Partner Detail View',
          description: '유저가 보는 파트너 상세 프로필',
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
