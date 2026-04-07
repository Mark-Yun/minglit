import 'package:app_user/src/features/consent/logic/consent_coordinator.dart';
import 'package:app_user/src/features/consent/ui/signup_consent_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

class MockConsentRepository extends Mock implements ConsentRepository {}

class MockUser extends Mock implements User {}

void main() {
  late MockConsentRepository mockRepository;
  late MockUser mockUser;
  late _FakeConsentCoordinator coordinator;

  setUp(() {
    mockRepository = MockConsentRepository();
    mockUser = MockUser();
    coordinator = _FakeConsentCoordinator();

    when(() => mockUser.id).thenReturn('user_1');
    when(
      () => mockRepository.getConsents('user_1'),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.saveConsents('user_1', any()),
    ).thenAnswer((_) async {});
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    String? from,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          consentRepositoryProvider.overrideWithValue(mockRepository),
          currentUserProvider.overrideWithValue(mockUser),
          consentCoordinatorProvider.overrideWithValue(coordinator),
        ],
        child: MaterialApp(
          theme: MinglitTheme.materialTheme,
          home: SignupConsentPage(from: from),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('초기 상태에서 6개 항목이 보이고 CTA는 비활성화된다', (tester) async {
    await pumpPage(tester);

    expect(find.text('환영합니다!'), findsOneWidget);
    expect(find.text('서비스 이용약관'), findsOneWidget);
    expect(find.text('개인정보 수집·이용 동의'), findsOneWidget);
    expect(find.text('만 14세 이상 확인'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('제3자 제공 동의'), 200);
    expect(find.text('제3자 제공 동의'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('본인인증(CI/DI) 수집 동의'), 200);
    expect(find.text('본인인증(CI/DI) 수집 동의'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('마케팅 정보 수신 동의'), 200);
    expect(find.text('마케팅 정보 수신 동의'), findsOneWidget);

    final cta = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '동의하고 시작하기'),
    );
    expect(cta.onPressed, isNull);
  });

  testWidgets('전체 동의를 켜면 모든 항목이 선택되고 CTA가 활성화된다', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('전체 동의'));
    await tester.pumpAndSettle();

    final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
    expect(checkboxes.every((checkbox) => checkbox.value ?? false), isTrue);

    final cta = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '동의하고 시작하기'),
    );
    expect(cta.onPressed, isNotNull);
  });

  testWidgets('필수 3개만 선택해도 CTA가 활성화된다', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.text('서비스 이용약관'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('개인정보 수집·이용 동의'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('만 14세 이상 확인'));
    await tester.pumpAndSettle();

    final cta = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '동의하고 시작하기'),
    );
    expect(cta.onPressed, isNotNull);
  });

  testWidgets('보기 버튼을 누르면 약관 상세 바텀시트가 열린다', (tester) async {
    await pumpPage(tester);

    // Fix #966: '보기' TextButton → '보기 ›' GestureDetector
    await tester.tap(find.text('보기 ›').first);
    await tester.pumpAndSettle();

    expect(find.text('이용자 보호'), findsOneWidget);
    expect(find.text('서비스 이용을 위해 필요한 기본 권리와 의무를 안내합니다.'), findsOneWidget);
  });

  // Fix #1141: 제3자 제공 동의 상세 바텀시트에 확정 항목/보유기간이 표시되는지 회귀 테스트
  testWidgets('제3자 제공 동의 상세에 확정된 제공 항목과 보유기간이 표시된다', (tester) async {
    await pumpPage(tester);

    // '보기 ›' 인덱스: termsOfService=0, privacyCollection=1, ageConfirmation=없음, thirdPartyProvision=2
    // GestureDetector(opaque) + InkWell 제스처 아레나 충돌로 ancestor 방식 미작동 — 직접 인덱스로 탭
    await tester.scrollUntilVisible(find.text('보기 ›').at(2), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('보기 ›').at(2));
    await tester.pumpAndSettle();

    expect(find.text('이름(닉네임)'), findsOneWidget);
    expect(find.text('연령대'), findsOneWidget);
    expect(find.text('자격 인증 정보(직업/소속 — 본인인증 완료 유저만)'), findsOneWidget);
    expect(find.text('이벤트 종료 후 30일'), findsOneWidget);
    // Fix #1141: 거부 권리 문구 — 0929d567 커밋에서 확정된 문구와 일치
    expect(
      find.text('동의를 거부할 수 있으며, 기본 서비스 이용은 가능합니다.'),
      findsOneWidget,
    );
    expect(
      find.text('다만 파트너 승인/확인이 필요한 이벤트는 신청 또는 참여가 제한될 수 있습니다.'),
      findsOneWidget,
    );
  });

  testWidgets('저장 성공 시 선택한 동의를 저장하고 원래 경로로 이동한다', (tester) async {
    await pumpPage(tester, from: '/tickets/my');

    await tester.tap(find.text('서비스 이용약관'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('개인정보 수집·이용 동의'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('만 14세 이상 확인'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, '동의하고 시작하기'));
    await tester.pumpAndSettle();

    final captured =
        verify(
              () => mockRepository.saveConsents('user_1', captureAny()),
            ).captured.single
            as List<ConsentInput>;

    expect(
      captured.map((input) => input.consentKey),
      containsAll(ConsentType.requiredTypes),
    );
    expect(captured, hasLength(3));
    expect(coordinator.lastFrom, '/tickets/my');
  });
}

class _FakeConsentCoordinator extends ConsentCoordinator {
  _FakeConsentCoordinator()
    : super(
        GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const SizedBox.shrink(),
            ),
          ],
        ),
      );

  String? lastFrom;

  @override
  void completeSignup({String? from}) {
    lastFrom = from;
  }
}
