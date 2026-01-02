import 'package:app_partner/src/features/admin/partner_application_detail_page.dart';
import 'package:app_partner/src/features/verification/review_verification_page.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PartnerDevMap extends StatelessWidget {
  const PartnerDevMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DevScreenList(
        appName: 'Minglit Partner',
        items: [
          DevScreenItem(
            category: 'Party',
            title: 'Manage Parties',
            description: '파티 및 회차 관리 (목록/상세)',
            onTap: (context, ref) => const PartyListRoute().push<void>(context),
          ),
          DevScreenItem(
            category: 'Party',
            title: 'Create Party',
            description: '새로운 파티 생성',
            onTap: (context, ref) =>
                const PartyCreateRoute().push<void>(context),
          ),
          DevScreenItem(
            category: 'Verification',
            title: 'Create Verification',
            description: '새로운 인증 요구사항 생성 (커스텀 폼)',
            onTap: (context, ref) =>
                const CreateVerificationRoute().push<void>(context),
          ),
          DevScreenItem(
            category: 'Auth',
            title: 'Login',
            description: '파트너 로그인 화면',
            onTap: (context, ref) => const LoginRoute().push<void>(context),
          ),
          DevScreenItem(
            category: 'Auth',
            title: 'Session Switcher',
            description: '테스트 유저 계정으로 즉시 전환',
            onTap: (context, ref) =>
                const DevUserSwitchRoute().push<void>(context),
          ),
          DevScreenItem(
            category: 'Dashboard',
            title: 'Main Dashboard',
            description: '메인 관리 대시보드',
            onTap: (context, ref) => const HomeRoute().push<void>(context),
          ),
          DevScreenItem(
            category: 'Admin',
            title: 'Application List',
            description: '파트너 입점 신청 목록 (관리자)',
            onTap: (context, ref) =>
                const ApplicationListRoute().push<void>(context),
          ),
          DevScreenItem(
            category: 'Admin',
            title: 'Application Detail',
            description: '입점 신청 상세 정보 및 심사',
            screenBuilder: (_) =>
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
          DevScreenItem(
            category: 'System',
            title: 'Reset & Seed DB',
            description: '데이터베이스 초기화 및 시딩 (경고: 모든 데이터 삭제됨)',
            onTap: (context, ref) async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('경고'),
                  content: const Text('정말 DB를 초기화하시겠습니까?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('초기화'),
                    ),
                  ],
                ),
              );

              if (confirmed != true) return;

              final notifier = ref.read(
                globalLoadingControllerProvider.notifier,
              )..show();

              try {
                // Call Supabase Admin function to truncate tables (if exists)
                // Or just run seeder which might rely on clean state.
                // Since we can't run 'supabase db reset' from here,
                // we assume Seeder handles cleanup or we just overwrite.
                // NOTE: Proper reset requires SQL execution or Admin API.
                // For now, let's just run seeder.
                final seeder = DatabaseSeeder(Supabase.instance.client);
                await seeder.seed();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('시딩 완료!')),
                  );
                }
              } on Object catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('시딩 실패: $e')),
                  );
                }
              } finally {
                notifier.hide();
              }
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
