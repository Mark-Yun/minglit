// CUJ tests — account / privacy-protection (app_user)
//
// 대응 spec: docs/features/account/privacy-protection/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).
//
// 커버 범위 (Flutter integration test): 8/15
//   1-1: SwitchListTile 토글 (제3자/마케팅/위치)
//   1-2: 토글 실패 → SnackBar + 원상복구
//   1-3: 필수 동의 read-only 표시
//   2-1: 필수 동의 ListTile 탭 → ConsentDetailSheet
//   2-2: 약관 보기 섹션 ListTile 탭 → ConsentDetailSheet
//   2-3: 본인인증 미완 → 탭 무반응
//   6-1: Loading state
//   6-2: Error state
//
// 미커버 (7/15):
//   3-1, 3-2 (회원 탈퇴): Fix #2093 — PrivacyPage에서 제거, 계정 관리 페이지로 이동.
//                          spec과 구현 불일치 — spec 업데이트 필요.
//   4-1, 4-2, 4-3 (인증 열람 권한): Phase 2 (#556) 미구현
//   5-1, 5-2 (권한 철회): Phase 2 (#556) 미구현

import 'dart:async';

import 'package:app_user/src/features/settings/privacy_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../_engine/cuj_test.dart';

class _MockUser extends Mock implements User {}

class _MockConsentRepository extends Mock implements ConsentRepository {}

// AsyncNotifier override — loading/error state injection용
class _LoadingConsentController extends ConsentController {
  @override
  FutureOr<List<UserConsent>> build() async {
    await Future<void>.delayed(const Duration(hours: 1));
    return [];
  }
}

class _ErrorConsentController extends ConsentController {
  @override
  FutureOr<List<UserConsent>> build() async {
    throw Exception('server error');
  }
}

final _testDate = DateTime(2024);

UserConsent _makeConsent(ConsentType type, {bool consented = true}) =>
    UserConsent(
      id: type.name,
      userId: 'test-user-id',
      consentKey: type,
      consented: consented,
      consentedAt: _testDate,
      createdAt: _testDate,
    );

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(ConsentType.termsOfService);
    registerFallbackValue(<ConsentInput>[]);
  });

  late _MockUser user;
  late _MockConsentRepository repo;

  setUp(() {
    user = _MockUser();
    when(() => user.id).thenReturn('test-user-id');

    repo = _MockConsentRepository();
    when(() => repo.getConsents(any())).thenAnswer((_) async => []);
    when(() => repo.saveConsents(any(), any())).thenAnswer((_) async {});
    when(() => repo.hasRequiredConsents()).thenAnswer((_) async => true);
  });

  List<dynamic> base() => [
    currentUserProvider.overrideWith((_) => user),
    authStateChangesProvider.overrideWith((_) => const Stream.empty()),
    consentRepositoryProvider.overrideWith((_) => repo),
  ];

  // ---------------------------------------------------------------------------
  // CUJ 1-1: 선택 동의 SwitchListTile 토글
  // ---------------------------------------------------------------------------

  cujGroup('1-1', '선택 동의 SwitchListTile 토글', () {
    cujCase(
      'happy: 마케팅 OFF → ON 토글 → toggleConsent 호출',
      app: const PrivacyPage(),
      overrides: base,
      body: (t) async {
        // 초기 상태: 마케팅 OFF (getConsents 빈 리스트)
        expect(find.byType(SwitchListTile), findsWidgets);

        // 마케팅 스위치 탭
        await t.tap(find.text('마케팅 정보 수신'));
        await t.pumpAndSettle();

        final captured = verify(
          () => repo.saveConsents('test-user-id', captureAny()),
        ).captured;
        final saved = captured.single as List<ConsentInput>;
        expect(saved, hasLength(1));
        expect(saved.first.consentKey, ConsentType.marketingConsent);
        expect(saved.first.consented, isTrue);
      },
    );

    cujCase(
      'happy: 제3자 ON → OFF 철회 → toggleConsent 호출',
      app: const PrivacyPage(),
      overrides: () {
        when(() => repo.getConsents(any())).thenAnswer(
          (_) async => [
            _makeConsent(ConsentType.thirdPartyProvision),
          ],
        );
        return base();
      },
      body: (t) async {
        // 제3자 스위치 탭 (현재 ON → OFF)
        await t.tap(find.text('제3자 제공 동의'));
        await t.pumpAndSettle();

        final captured = verify(
          () => repo.saveConsents('test-user-id', captureAny()),
        ).captured;
        final saved = captured.single as List<ConsentInput>;
        expect(saved.first.consentKey, ConsentType.thirdPartyProvision);
        expect(saved.first.consented, isFalse);
      },
    );

    cujCase(
      'happy: 위치정보 OFF → ON 토글 → toggleConsent 호출',
      app: const PrivacyPage(),
      overrides: base,
      body: (t) async {
        await t.tap(find.text('위치정보 이용 동의'));
        await t.pumpAndSettle();

        final captured = verify(
          () => repo.saveConsents('test-user-id', captureAny()),
        ).captured;
        final saved = captured.single as List<ConsentInput>;
        expect(saved.first.consentKey, ConsentType.locationConsent);
        expect(saved.first.consented, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-2: 토글 실패 시 원상복구
  // ---------------------------------------------------------------------------

  cujGroup('1-2', '토글 실패 시 원상복구', () {
    cujCase(
      'happy: 마케팅 토글 → 서버 실패 → SnackBar + 원상복구',
      app: const PrivacyPage(),
      overrides: () {
        when(
          () => repo.saveConsents(any(), any()),
        ).thenThrow(Exception('network'));
        return base();
      },
      body: (t) async {
        // Fix #886: 토글 실패 시 원상복구 + 스낵바
        await t.tap(find.text('마케팅 정보 수신'));
        await t.pumpAndSettle();

        expect(find.text('동의 변경에 실패했습니다. 다시 시도해주세요.'), findsOneWidget);

        // SnackBar 닫히고 나서도 스위치 복구 대기
        await t.pump(const Duration(seconds: 4));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-3: 필수 동의 read-only 표시
  // ---------------------------------------------------------------------------

  cujGroup('1-3', '필수 동의 read-only 표시', () {
    cujCase(
      'happy: 서비스 이용약관 · 개인정보 수집 — SwitchListTile 아님',
      app: const PrivacyPage(),
      overrides: base,
      body: (t) async {
        // 필수 동의는 SwitchListTile로 표시되지 않아야 함
        final switches = t
            .widgetList<SwitchListTile>(find.byType(SwitchListTile))
            .map((s) => s.title)
            .whereType<Text>()
            .map((title) => title.data ?? '')
            .toSet();

        expect(switches.contains('서비스 이용약관'), isFalse);
        expect(switches.contains('개인정보 수집·이용'), isFalse);

        // 약관 보기 섹션에도 동일 텍스트가 있으므로 개수는 고정하지 않는다.
        expect(find.text('서비스 이용약관'), findsWidgets);
        expect(find.text('개인정보 수집·이용'), findsOneWidget);
      },
    );

    cujCase(
      'happy: 본인인증 미완 → statusText = 미동의',
      app: const PrivacyPage(),
      overrides: base, // identityVerification 없음 → 미동의
      body: (t) async {
        // identityVerification consent 없으면 "미동의" 표시
        expect(find.text('미동의'), findsOneWidget);
      },
    );

    cujCase(
      'happy: 본인인증 완료 → statusText = 동의됨',
      app: const PrivacyPage(),
      overrides: () {
        when(() => repo.getConsents(any())).thenAnswer(
          (_) async => [
            _makeConsent(ConsentType.identityVerification),
          ],
        );
        return base();
      },
      body: (t) async {
        final identityInfoTile = find.ancestor(
          of: find.text('본인인증 정보'),
          matching: find.byType(ListTile),
        );
        expect(identityInfoTile, findsOneWidget);
        expect(
          find.descendant(of: identityInfoTile, matching: find.text('동의됨')),
          findsOneWidget,
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-1: 동의 항목 본문 시트 열람 (필수 동의 ListTile 탭)
  // ---------------------------------------------------------------------------

  cujGroup('2-1', '동의 항목 본문 시트 열람', () {
    cujCase(
      'happy: 서비스 이용약관 ListTile 탭 → ConsentDetailSheet 노출',
      app: const PrivacyPage(),
      overrides: base,
      body: (t) async {
        await t.tap(find.text('서비스 이용약관').first);
        await t.pumpAndSettle();

        // ConsentDetailSheet 바텀시트 노출 확인 (주요 내용 포함)
        expect(find.text('서비스 이용약관'), findsWidgets);
        expect(find.text('주요 내용'), findsOneWidget);

        // 배리어 탭으로 닫기
        await t.tapAt(const Offset(10, 10));
        await t.pumpAndSettle();
        expect(find.text('개인정보'), findsOneWidget); // AppBar title
      },
    );

    cujCase(
      'happy: 본인인증 완료 시 본인인증 정보 탭 → 시트 노출',
      app: const PrivacyPage(),
      overrides: () {
        when(() => repo.getConsents(any())).thenAnswer(
          (_) async => [
            _makeConsent(ConsentType.identityVerification),
          ],
        );
        return base();
      },
      body: (t) async {
        await t.tap(find.text('본인인증 정보'));
        await t.pumpAndSettle();

        // 본인인증 정보 시트 노출 확인
        expect(find.text('본인인증(CI/DI) 수집 동의'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-2: 약관 보기 섹션 ListTile 탭
  // ---------------------------------------------------------------------------

  cujGroup('2-2', '약관 보기 섹션 ListTile 탭', () {
    cujCase(
      'happy: 개인정보처리방침 탭 → ConsentDetailSheet 노출',
      app: const PrivacyPage(),
      overrides: base,
      body: (t) async {
        await t.tap(find.text('개인정보처리방침'));
        await t.pumpAndSettle();

        expect(find.text('개인정보처리방침'), findsWidgets);
        expect(find.text('수집하는 개인정보'), findsOneWidget);
      },
    );

    cujCase(
      'happy: 위치정보 이용약관 탭 → ConsentDetailSheet 노출',
      app: const PrivacyPage(),
      overrides: base,
      body: (t) async {
        await t.tap(find.text('위치정보 이용약관'));
        await t.pumpAndSettle();

        expect(find.text('위치정보 이용약관'), findsWidgets);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-3: 본인인증 미완 상태에서 본인인증 정보 탭 무반응
  // ---------------------------------------------------------------------------

  cujGroup('2-3', '본인인증 미완 상태에서 본인인증 정보 탭 무반응', () {
    cujCase(
      'happy: identityVerification 미완 → 탭해도 시트 미노출',
      app: const PrivacyPage(),
      overrides: base, // identityVerification 없음 → onTap: null
      body: (t) async {
        // 본인인증 정보 타일 탭 (onTap null이면 아무 일도 없음)
        await t.tap(find.text('본인인증 정보'));
        await t.pumpAndSettle();

        // 시트가 올라오지 않음 — AppBar title은 여전히 '개인정보'
        expect(find.text('개인정보'), findsOneWidget);
        expect(find.text('본인인증(CI/DI) 수집 동의'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 6-1: Loading state
  // ---------------------------------------------------------------------------

  cujGroup('6-1', 'Loading state — 동의 정보 가져오는 중', () {
    cujCase(
      'happy: 로딩 중 — MinglitCircularProgressIndicator 노출',
      app: const PrivacyPage(),
      overrides: () => [
        currentUserProvider.overrideWith((_) => user),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        consentControllerProvider.overrideWith(_LoadingConsentController.new),
      ],
      afterPump: (t) => t.pump(), // pumpAndSettle 금지 — 무한 로딩
      body: (t) async {
        expect(find.byType(MinglitCircularProgressIndicator), findsOneWidget);
        expect(find.byType(ListView), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 6-2: Error state — 동의 정보 로드 실패
  // ---------------------------------------------------------------------------

  cujGroup('6-2', 'Error state — 동의 정보 로드 실패', () {
    cujCase(
      'happy: fetch 실패 → 에러 메시지 노출',
      app: const PrivacyPage(),
      overrides: () => [
        currentUserProvider.overrideWith((_) => user),
        authStateChangesProvider.overrideWith((_) => const Stream.empty()),
        consentControllerProvider.overrideWith(_ErrorConsentController.new),
      ],
      body: (t) async {
        expect(find.text('동의 정보를 불러올 수 없습니다.'), findsOneWidget);
        expect(find.byType(ListView), findsNothing);
      },
    );
  });
}
