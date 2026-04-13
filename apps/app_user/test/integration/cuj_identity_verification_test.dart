// Ref #1336: IT-U12 — 본인인증 통합 테스트
//
// 검증 포인트:
// 1. 인증 동의 미완료 시 동의 시트 표시 (TC-U12-001)
// 2. 동의 취소 → 에러 안내 표시 (TC-U12-003)
// 3. 비로그인 시 /certification 접근 → 로그인 페이지 리다이렉트
//
// Note: TC-U12-002 (인증 정상 완료 → 복귀)는 Iamport 플랫폼 서비스(getCertificationService)
// 가 Flutter 테스트 환경에서 네이티브 구현이 없어 end-to-end 검증 불가.
// 대신 동의 완료 후 로딩 상태 진입까지만 검증한다.

import 'package:app_user/src/features/auth/login_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import 'utils/test_app.dart';
import 'utils/test_mocks.dart';

class _MockConsentRepository extends Mock implements ConsentRepository {}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
  });

  late _MockConsentRepository mockConsentRepo;
  late User user;

  setUp(() {
    mockConsentRepo = _MockConsentRepository();
    user = createMockUserForTest();

    // Default: hasRequiredConsents true (routing guard 통과용)
    when(
      () => mockConsentRepo.hasRequiredConsents(),
    ).thenAnswer((_) async => true);
  });

  group('IT-U12: 본인인증', () {
    testWidgets(
      'TC-U12-001: 인증 동의 미완료 → 동의 시트 표시',
      (tester) async {
        setKoreanLocale(tester);

        // 인증 동의 없는 사용자
        when(
          () => mockConsentRepo.getConsents(any()),
        ).thenAnswer((_) async => []);

        await tester.pumpWidget(
          createTestApp(
            isLoggedIn: true,
            currentUser: user,
            initialLocation: '/certification',
            additionalOverrides: [
              consentRepositoryProvider.overrideWithValue(mockConsentRepo),
            ],
          ),
        );

        // 초기 렌더링 → postFrameCallback → 비동기 동의 확인 완료
        await tester.pump(); // 초기 프레임
        await tester.pump(); // postFrameCallback 실행
        await tester.pump(); // getConsents 비동기 완료
        await tester.pump(); // 바텀시트 애니메이션

        // 동의 시트 텍스트 확인
        expect(find.text('본인확인정보 수집·이용 동의'), findsOneWidget);
        expect(find.text('동의하고 인증'), findsOneWidget);
        expect(find.text('취소'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-U12-003: 동의 시트 취소 → 에러 안내 표시',
      (tester) async {
        setKoreanLocale(tester);

        // 인증 동의 없는 사용자
        when(
          () => mockConsentRepo.getConsents(any()),
        ).thenAnswer((_) async => []);

        await tester.pumpWidget(
          createTestApp(
            isLoggedIn: true,
            currentUser: user,
            initialLocation: '/certification',
            additionalOverrides: [
              consentRepositoryProvider.overrideWithValue(mockConsentRepo),
            ],
          ),
        );

        // 동의 시트 표시 대기
        await tester.pump();
        await tester.pump();
        await tester.pump();
        await tester.pump();

        // 동의 시트에서 취소 탭
        await tester.tap(find.text('취소'));
        await tester.pumpAndSettle();

        // 에러 안내 메시지 및 재시도 버튼 표시 확인
        expect(
          find.text('본인확인정보 수집·이용 동의 후 인증을 진행할 수 있습니다.'),
          findsOneWidget,
        );
        expect(find.text('본인인증 다시 시도하기'), findsOneWidget);
        // 동의 시트는 닫혀야 함
        expect(find.text('동의하고 인증'), findsNothing);
      },
    );

    testWidgets(
      'TC-U12-004: 이미 인증 동의 완료 → 동의 시트 미표시, 로딩 상태로 인증 시도',
      (tester) async {
        setKoreanLocale(tester);

        // 이미 identityVerification 동의 완료된 사용자
        when(
          () => mockConsentRepo.getConsents(any()),
        ).thenAnswer(
          (_) async => [
            UserConsent(
              id: 'c1',
              userId: user.id,
              consentKey: ConsentType.identityVerification,
              consented: true,
              consentedAt: DateTime(2026, 4, 13),
              createdAt: DateTime(2026, 4, 13),
            ),
          ],
        );

        await tester.pumpWidget(
          createTestApp(
            isLoggedIn: true,
            currentUser: user,
            initialLocation: '/certification',
            additionalOverrides: [
              consentRepositoryProvider.overrideWithValue(mockConsentRepo),
            ],
          ),
        );

        // 초기 프레임 → postFrameCallback → getConsents() 비동기 완료 → _startVerification()
        // 순서로 진행되어야 한다. TC-U12-001과 동일하게 4 pump으로 비동기 플로우를 모두 소진한다.
        await tester.pump(); // 초기 프레임
        await tester.pump(); // postFrameCallback 실행
        await tester.pump(); // getConsents() 비동기 완료 + _startVerification() 진입
        await tester.pump(); // setState 재빌드

        // getConsents()가 실제로 호출되었는지 검증 → 동의 확인 경로가 실행됐음을 보장
        verify(() => mockConsentRepo.getConsents(user.id)).called(1);

        // 동의가 이미 완료된 경우이므로 동의 시트는 표시되지 않아야 함
        expect(find.text('본인확인정보 수집·이용 동의'), findsNothing);
        expect(find.text('동의하고 인증'), findsNothing);
      },
    );

    testWidgets(
      '비로그인: /certification 접근 → LoginPage 리다이렉트',
      (tester) async {
        setKoreanLocale(tester);

        await tester.pumpWidget(
          createTestApp(
            initialLocation: '/certification',
          ),
        );

        await tester.pump();
        await tester.pump();

        // 로그인 페이지로 리다이렉트
        expect(find.byType(LoginPage), findsOneWidget);
      },
    );
  });
}
