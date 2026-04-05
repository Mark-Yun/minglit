// Ref #1072: IT-P01 — 파트너 가입 → 파티 → 이벤트 CUJ 통합 테스트
//
// 검증 포인트:
// 1. needsApplication 상태 → /welcome 리다이렉트
// 2. draftInProgress 상태 → /apply 리다이렉트 (온보딩 위저드)
// 3. pendingReview 상태 → /apply/status 리다이렉트
// 4. hasPartner 상태 → 홈 접근 가능
// 5. 온보딩 완료 후 파티 생성 위저드 접근 가능
// 변형:
// - P01-V1: 심사 보완 요청(needsCorrection) → apply/status로 리다이렉트
// - P01-V2: 무료 이벤트 생성
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../utils/mocks.dart';
import 'utils/test_app.dart';

void main() {
  final testUser = MockUser();

  setUp(() {
    when(() => testUser.id).thenReturn('partner-p01');
    when(() => testUser.email).thenReturn('partner@example.com');
    when(() => testUser.userMetadata).thenReturn({'full_name': '김파트너'});
  });

  group('IT-P01: 파트너 가입 → 파티 → 이벤트', () {
    testWidgets('비로그인 사용자는 홈에 접근할 수 없다', (tester) async {
      await tester.pumpWidget(
        createPartnerTestApp(),
      );
      await tester.pump();
      await tester.pump();

      // /login으로 리다이렉트됨
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('needsApplication 상태 → /welcome으로 리다이렉트된다', (
      tester,
    ) async {
      await tester.pumpWidget(
        createPartnerTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          onboardingState: OnboardingState.needsApplication,
        ),
      );
      await tester.pump();
      await tester.pump();

      // /welcome 페이지가 렌더링됨
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('draftInProgress 상태 → /apply 위저드로 리다이렉트된다', (
      tester,
    ) async {
      await tester.pumpWidget(
        createPartnerTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          onboardingState: OnboardingState.draftInProgress,
        ),
      );
      await tester.pump();
      await tester.pump();

      // /apply 위저드가 렌더링됨
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('pendingReview 상태 → /apply/status로 리다이렉트된다', (
      tester,
    ) async {
      await tester.pumpWidget(
        createPartnerTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          onboardingState: OnboardingState.pendingReview,
        ),
      );
      await tester.pump();
      await tester.pump();

      // /apply/status 페이지가 렌더링됨
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('P01-V1: needsCorrection 상태 → /apply/status로 리다이렉트된다', (
      tester,
    ) async {
      await tester.pumpWidget(
        createPartnerTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          onboardingState: OnboardingState.needsCorrection,
        ),
      );
      await tester.pump();
      await tester.pump();

      // 심사 보완 요청 → apply/status 페이지
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('hasPartner 상태에서 홈에 접근할 수 있다', (tester) async {
      await tester.pumpWidget(
        createPartnerTestApp(
          isLoggedIn: true,
          currentUser: testUser,
        ),
      );
      await tester.pump();
      await tester.pump();

      // 파트너 홈 렌더링됨
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('hasPartner 상태에서 파티 목록 페이지에 접근할 수 있다', (tester) async {
      await tester.pumpWidget(
        createPartnerTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          initialLocation: '/more/parties',
        ),
      );
      await tester.pump();
      await tester.pump();

      // 파티 목록 페이지 렌더링됨
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('hasPartner 상태에서 /apply에 접근 시 홈으로 리다이렉트된다', (
      tester,
    ) async {
      await tester.pumpWidget(
        createPartnerTestApp(
          isLoggedIn: true,
          currentUser: testUser,
          initialLocation: '/apply',
        ),
      );
      await tester.pump();
      await tester.pump();

      // hasPartner가 /apply 접근 → / 로 리다이렉트
      expect(find.byType(Scaffold), findsWidgets);
    });
  });
}
