import 'package:app_user/src/features/auth/auth_wrapper.dart';
import 'package:app_user/src/routing/app_routes.dart';
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
          // ── PUBLIC ROUTES (로그인 불필요) ──
          DevScreenItem(
            category: 'Public',
            title: 'Home /',
            description: '메인 홈 화면 (파티 목록)',
            onTap: (context, ref) => const HomeRoute().push<void>(context),
          ),
          DevScreenItem(
            category: 'Public',
            title: 'Curation: New Arrivals',
            description: '신규 오픈 파티 목록 /curation',
            onTap: (context, ref) =>
                const EventCurationRoute().push<void>(context),
          ),
          DevScreenItem(
            category: 'Public',
            title: 'Curation: Closing Soon',
            description: '마감 임박 파티 목록',
            onTap: (context, ref) => const EventCurationRoute(
              type: EventFeedType.closingSoon,
            ).push<void>(context),
          ),
          DevScreenItem(
            category: 'Public',
            title: 'Curation: Nearest',
            description: '내 주변 파티 목록',
            onTap: (context, ref) => const EventCurationRoute(
              type: EventFeedType.nearest,
            ).push<void>(context),
          ),
          DevScreenItem(
            category: 'Public',
            title: 'Curation: Early Bird',
            description: '얼리버드 특가 파티 목록',
            onTap: (context, ref) => const EventCurationRoute(
              type: EventFeedType.earlyBird,
            ).push<void>(context),
          ),

          // ── PROTECTED ROUTES (로그인 필수) ──
          DevScreenItem(
            category: 'Protected',
            title: 'My Page /my',
            description: '마이페이지 (로그인 필수)',
            onTap: (context, ref) => const MyPageRoute().push<void>(context),
          ),
          DevScreenItem(
            category: 'Protected',
            title: 'Purchase History',
            description: '구매 내역 /purchase-history (로그인 필수)',
            onTap: (context, ref) =>
                const PurchaseHistoryRoute().push<void>(context),
          ),
          DevScreenItem(
            category: 'Protected',
            title: 'Identity Verification',
            description: '본인인증 /certification (로그인 필수)',
            onTap: (context, ref) =>
                const CertificationRoute().push<void>(context),
          ),
          DevScreenItem(
            category: 'Protected',
            title: 'Notification Settings',
            description: '알림 설정 /my/notification-settings (로그인 필수)',
            onTap: (context, ref) =>
                const NotificationSettingsRoute().push<void>(context),
          ),

          // ── AUTH ──
          DevScreenItem(
            category: 'Auth',
            title: 'Login',
            description: '로그인 및 소셜 가입 화면',
            onTap: (context, ref) => const LoginRoute().push<void>(context),
          ),
          DevScreenItem(
            category: 'Auth',
            title: 'Session Switcher',
            description: '테스트 유저 계정으로 즉시 전환',
            onTap: (context, ref) =>
                const DevUserSwitchRoute().push<void>(context),
          ),

          // ── APP FLOW ──
          DevScreenItem(
            category: 'App Flow',
            title: 'App Entry (Auth Wrapper)',
            description: '인증 상태에 따른 자동 분기 흐름',
            screenBuilder: (_) => const AuthWrapper(),
          ),

          // ── PREVIEW ──
          DevScreenItem(
            category: 'Preview',
            title: 'Partner List Preview',
            description: '생성된 모든 파트너 목록 및 상세 화면 확인',
            screenBuilder: (_) => const PartnerListPreviewScreen(),
          ),
          DevScreenItem(
            category: 'Preview',
            title: 'Party List Preview',
            description: '생성된 모든 파티 목록 확인',
            screenBuilder: (_) => const PartyListPreviewScreen(),
          ),

          // ── SYSTEM ──
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
          const DevUserSwitchRoute().push<void>(context);
        },
        child: const Icon(Icons.people_alt),
      ),
    );
  }
}
