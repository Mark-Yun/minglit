import 'package:app_partner/main.dart';
import 'package:app_partner/src/features/admin/partner_application_detail_page.dart';
import 'package:app_partner/src/features/admin/partner_application_list_page.dart';
import 'package:app_partner/src/features/auth/partner_application_page.dart';
import 'package:app_partner/src/features/member/partner_member_list_page.dart'; // 추가
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
          title: 'Partner Application',
          description: '파트너 입점 신청 폼',
          screenBuilder: (_) => const PartnerApplicationPage(),
        ),
        DevScreenItem(
          title: 'Manage Members & Permissions',
          description: '직원 목록 조회 및 세부 권한 설정',
          screenBuilder:
              (_) => const PartnerMemberListPage(
                partnerId: '00000000-0000-0000-0000-000000000000',
              ),
        ),
        DevScreenItem(
          title: 'Partner Home',
          description: '파트너 메인 홈 (대시보드)',
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
          title: 'Admin: Application Detail (Dummy)',
          description: '관리자: 파트너 신청서 상세 심사 (더미 데이터)',
          screenBuilder:
              (_) => const PartnerApplicationDetailPage(
                application: PartnerApplication(
                  id: 'dummy-app-id',
                  userId: 'dummy-user-id',
                  brandName: '테스트 카페',
                  introduction: '안녕하세요, 강남역 부근에 위치한 조용한 카페입니다.',
                  address: '서울시 강남구 역삼동 123-45',
                  contactPhone: '010-1234-5678',
                  contactEmail: 'test@cafe.com',
                  bizType: 'individual',
                  bizName: '홍길동커피',
                  bizNumber: '123-45-67890',
                  representativeName: '홍길동',
                  bankName: '우리은행',
                  accountNumber: '1002-123-456789',
                  accountHolder: '홍길동',
                  bizRegistrationPath: 'dummy/biz.jpg',
                  bankbookPath: 'dummy/bank.jpg',
                ),
              ),
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
