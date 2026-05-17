// CUJ tests — account / signup-consent
//
// 대응 spec: docs/features/account/signup-consent/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).

import 'package:app_user/src/features/consent/logic/consent_coordinator.dart';
import 'package:app_user/src/features/consent/ui/signup_consent_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mds/mds.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../_engine/cuj_test.dart';

class _MockUser extends Mock implements User {}

class _MockConsentRepository extends Mock implements ConsentRepository {}

class _MockConsentCoordinator extends Mock implements ConsentCoordinator {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(<ConsentInput>[]);
  });

  late _MockUser user;
  late _MockConsentRepository repo;
  late _MockConsentCoordinator coordinator;

  setUp(() {
    user = _MockUser();
    when(() => user.id).thenReturn('test-user-id');

    repo = _MockConsentRepository();
    when(() => repo.getConsents(any())).thenAnswer((_) async => []);
    when(() => repo.saveConsents(any(), any())).thenAnswer((_) async {});
    when(() => repo.hasRequiredConsents()).thenAnswer((_) async => false);

    coordinator = _MockConsentCoordinator();
  });

  List<dynamic> base() => [
    currentUserProvider.overrideWith((_) => user),
    authStateChangesProvider.overrideWith((_) => const Stream.empty()),
    consentRepositoryProvider.overrideWith((_) => repo),
    consentCoordinatorProvider.overrideWith((_) => coordinator),
  ];

  cujGroup('1-1', '필수 동의 3종 체크 후 가입', () {
    cujCase(
      'happy: 정상 가입',
      app: const SignupConsentPage(),
      overrides: base,
      body: (t) async {
        await t.tap(find.text('서비스 이용약관'));
        await t.tap(find.text('개인정보 수집·이용 동의'));
        await t.tap(find.text('만 14세 이상 확인'));
        await t.pumpAndSettle();

        // CTA 활성 확인 (FR-2)
        final cta = t.widget<MinglitBottomCTA>(find.byType(MinglitBottomCTA));
        expect(cta.enabled, isTrue);

        await t.tap(find.text('동의하고 시작하기'));
        await t.pumpAndSettle();

        // FR-3: bulk save with 3 required types
        final captured = verify(
          () => repo.saveConsents('test-user-id', captureAny()),
        ).captured;
        expect(captured.single, hasLength(3));
        final keys = (captured.single as List<ConsentInput>)
            .map((c) => c.consentKey)
            .toSet();
        expect(keys, equals(ConsentType.requiredTypes.toSet()));

        // FR-12: 가입 완료 후 HomePage 진입 (coordinator 위임)
        verify(
          () => coordinator.completeSignup(from: any(named: 'from')),
        ).called(1);
      },
    );

    cujCase(
      'edge: 14세 미체크 → CTA 비활성',
      app: const SignupConsentPage(),
      overrides: base,
      body: (t) async {
        await t.tap(find.text('서비스 이용약관'));
        await t.tap(find.text('개인정보 수집·이용 동의'));
        // 만 14세 안 누름
        await t.pumpAndSettle();

        final cta = t.widget<MinglitBottomCTA>(find.byType(MinglitBottomCTA));
        expect(cta.enabled, isFalse);
        expect(cta.onPressed, isNull);

        verifyNever(() => repo.saveConsents(any(), any()));
      },
    );

    cujCase(
      'edge: 저장 실패 → coordinator 미호출',
      app: const SignupConsentPage(),
      overrides: base,
      body: (t) async {
        when(
          () => repo.saveConsents(any(), any()),
        ).thenThrow(Exception('network'));

        await t.tap(find.text('서비스 이용약관'));
        await t.tap(find.text('개인정보 수집·이용 동의'));
        await t.tap(find.text('만 14세 이상 확인'));
        await t.tap(find.text('동의하고 시작하기'));
        await t.pumpAndSettle();

        // 저장 실패 시 가입 완료 흐름 차단 (FR-12 negative)
        verifyNever(
          () => coordinator.completeSignup(from: any(named: 'from')),
        );
      },
    );
  });
}
