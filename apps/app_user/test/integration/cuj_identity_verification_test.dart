// Ref #1336: IT-U12 — 본인인증 통합 테스트
//
// 검증 포인트:
// 1. 인증 동의 미완료 시 동의 시트 표시 (TC-U12-001)
// 2. 동의 취소 → 에러 안내 표시 (TC-U12-003)
// 3. 비로그인 시 /certification 접근 → 로그인 페이지 리다이렉트
//
// Note: TC-U12-002 (인증 정상 완료 → 복귀)는 Iamport 플랫폼 서비스(getCertificationService)
// 가 Flutter 테스트 환경에서 네이티브 구현이 없어 end-to-end 검증 불가.
// Note: TC-U12-004는 getCertificationService().verify()가 네이티브 IamportCertification을
// Navigator.push하므로, getConsents() 호출 직후까지만 검증하고 네이티브 경로 진입을 방지한다.

import 'package:app_user/src/features/auth/login_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import 'utils/golden_capture.dart';
import 'utils/test_app.dart';
import 'utils/test_mocks.dart';

class _MockConsentRepository extends Mock implements ConsentRepository {}

/// 동의 플로우의 4단계 비동기 프레임을 소진하는 헬퍼.
///
/// 순서: 초기 프레임 → postFrameCallback → getConsents 비동기 완료 → 후속 재빌드/애니메이션
Future<void> _drainConsentFlow(WidgetTester tester) async {
  await tester.pump(); // 초기 프레임
  await tester.pump(); // postFrameCallback
  await tester.pump(); // 비동기 getConsents 완료
  await tester.pump(); // 후속 재빌드/애니메이션 반영
}

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
    // Fix #1458: cuj_u08 → cuj_u12 to match IT-U12 scenario ID
    final capture = GoldenCapture('cuj_u12');

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
        await _drainConsentFlow(tester);

        await capture.setup(tester, 0);

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

        // 동의 시트 표시 대기 + 입장 애니메이션(250ms) 완료까지 시간 부여.
        // _drainConsentFlow(4 pumps ≈ 67ms)만으로는 입장 애니메이션이 26%에서
        // 중단되어, 취소 탭 후 역방향 퇴장 애니메이션 시간이 ~53ms로 짧아진다.
        // 짧은 퇴장 애니메이션 후 async 체인이 완결되지 않는 경우가 있어
        // 입장 애니메이션을 먼저 완전히 소진한 뒤 취소를 탭한다.
        await _drainConsentFlow(tester);
        await tester.pump(const Duration(milliseconds: 300)); // 입장 애니메이션 완료

        // Fix: isScrollControlled: true인 바텀시트에서 SingleChildScrollView
        // 컨텐츠가 뷰포트 높이를 초과하면 '취소' 버튼이 화면 밖에 위치하여
        // tester.tap()이 히트 테스트에서 실패한다. ensureVisible로 스크롤 후 탭한다.
        await tester.ensureVisible(find.text('취소'));
        await tester.pump();

        // 동의 시트에서 취소 탭
        await tester.tap(find.text('취소'));
        // Fix: pumpAndSettle()은 CircularProgressIndicator(indeterminate)가
        // 위젯 트리에 있으면 영원히 타임아웃된다 — ticker가 계속 프레임 요청.
        // 퇴장 애니메이션(~250ms)을 pump(300ms)로 소진하고,
        // 이후 pump()로 Future resolve + setState(_isLoading=false) 재빌드를 처리.
        await tester.pump(const Duration(milliseconds: 300)); // 퇴장 애니메이션
        await tester.pump(); // showModalBottomSheet Future resolve
        await tester.pump(); // setState(_isLoading=false) 재빌드

        await capture.after(tester, 2);

        // 에러 안내 메시지 및 재시도 버튼 표시 확인
        expect(
          find.text('본인확인정보 수집·이용 동의 후 인증을 진행할 수 있습니다.'),
          findsOneWidget,
        );
        expect(find.text('본인인증 다시 시도하기'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-U12-004: 이미 인증 동의 완료 → getConsents 호출됨, 동의 시트 미표시',
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

        // pump 1: 초기 프레임 렌더링
        // pump 2: postFrameCallback 실행 → _startVerificationFlow() 시작 →
        //         getConsents() 호출 (Future 생성, 호출 기록됨)
        // 여기서 의도적으로 멈춘다: getConsents()가 resolve되면 hasConsent=true이므로
        // _startVerification() → getCertificationService().verify() → 네이티브
        // IamportCertification Navigator.push로 진행되어 테스트 환경을 벗어난다.
        // 목적: getConsents()가 호출되었는지와 동의 시트가 표시되지 않는지만 검증한다.
        await tester.pump(); // 초기 프레임
        await tester.pump(); // postFrameCallback + getConsents() 호출
        // Fix #1677: capture.after() uses runAsync() which resolves getConsents(),
        // triggering _startVerification() → getCertificationService().verify() →
        // MissingPluginException in CI. Skip capture; verify call count + UI state only.

        // 동의 확인 경로가 실행되어 getConsents()가 호출되었는지 검증.
        // ConsentController.build()도 getConsents()를 호출하므로 greaterThanOrEqualTo(1) 사용.
        verify(
          () => mockConsentRepo.getConsents(any()),
        ).called(greaterThanOrEqualTo(1));

        // 동의가 이미 완료된 경우이므로 동의 시트는 절대 표시되지 않아야 함
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
