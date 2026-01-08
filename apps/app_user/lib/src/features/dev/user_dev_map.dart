import 'package:app_user/src/features/auth/auth_wrapper.dart';
import 'package:app_user/src/features/auth/login_page.dart';
import 'package:app_user/src/features/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class UserDevMap extends StatelessWidget {
  const UserDevMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DevScreenList(
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
