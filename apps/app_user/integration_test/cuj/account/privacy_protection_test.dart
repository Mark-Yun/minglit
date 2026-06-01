// CUJ tests — account / privacy-protection
//
// 대응 spec: docs/features/account/privacy-protection/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).

import 'dart:async';

import 'package:app_user/src/features/settings/privacy_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../_engine/cuj_test.dart';

class _MockConsentRepository extends Mock implements ConsentRepository {}

class _MockUser extends Mock implements User {}

UserConsent _consent({
  required String id,
  required ConsentType key,
  required bool consented,
}) {
  final now = DateTime(2026);
  return UserConsent(
    id: id,
    userId: 'user-1',
    consentKey: key,
    consented: consented,
    consentedAt: now,
    createdAt: now,
    withdrawnAt: consented ? null : now,
  );
}

List<UserConsent> _baseConsents({required bool identityVerified}) => [
  _consent(id: '1', key: ConsentType.termsOfService, consented: true),
  _consent(id: '2', key: ConsentType.privacyCollection, consented: true),
  _consent(id: '3', key: ConsentType.thirdPartyProvision, consented: false),
  _consent(id: '4', key: ConsentType.marketingConsent, consented: true),
  _consent(id: '5', key: ConsentType.locationConsent, consented: false),
  _consent(
    id: '6',
    key: ConsentType.identityVerification,
    consented: identityVerified,
  ),
];

SwitchListTile _switchTile(WidgetTester t, String label) {
  return t.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, label));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late _MockConsentRepository repo;
  late _MockUser user;

  setUp(() {
    repo = _MockConsentRepository();
    user = _MockUser();

    when(() => user.id).thenReturn('user-1');
    when(
      () => repo.getConsents('user-1'),
    ).thenAnswer((_) async => _baseConsents(identityVerified: true));
    when(() => repo.saveConsents('user-1', any())).thenAnswer((_) async {});
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
      'happy: 제3자 제공 동의 토글 시 저장 호출 + UI 반영',
      app: const PrivacyPage(),
      overrides: base,
      body: (t) async {
        expect(_switchTile(t, '제3자 제공 동의').value, isFalse);

        when(() => repo.getConsents('user-1')).thenAnswer(
          (_) async => _baseConsents(identityVerified: true)
              .map(
                (c) => c.consentKey == ConsentType.thirdPartyProvision
                    ? c.copyWith(consented: true, withdrawnAt: null)
                    : c,
              )
              .toList(),
        );

        await t.tap(find.widgetWithText(SwitchListTile, '제3자 제공 동의'));
        await t.pumpAndSettle();

        verify(() => repo.saveConsents('user-1', any())).called(1);
        expect(_switchTile(t, '제3자 제공 동의').value, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-2: 토글 실패 시 원상복구
  // ---------------------------------------------------------------------------
  cujGroup('1-2', '토글 실패 시 원상복구', () {
    cujCase(
      'edge: 저장 실패 시 스낵바 표시 + 서버 상태(false)로 복구',
      app: const PrivacyPage(),
      overrides: base,
      body: (t) async {
        when(
          () => repo.saveConsents('user-1', any()),
        ).thenThrow(Exception('save failed'));
        when(
          () => repo.getConsents('user-1'),
        ).thenAnswer((_) async => _baseConsents(identityVerified: true));

        await t.tap(find.widgetWithText(SwitchListTile, '제3자 제공 동의'));
        await t.pumpAndSettle();

        expect(
          find.text('동의 변경에 실패했습니다. 다시 시도해주세요.'),
          findsOneWidget,
        );
        expect(_switchTile(t, '제3자 제공 동의').value, isFalse);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-3: 필수 동의 read-only 표시
  // ---------------------------------------------------------------------------
  cujGroup('1-3', '필수 동의 read-only 표시', () {
    cujCase(
      'happy: 필수 동의 3개는 Switch가 아니라 ListTile 상태 텍스트로 노출',
      app: const PrivacyPage(),
      overrides: base,
      body: (t) async {
        expect(find.text('서비스 이용약관'), findsAtLeast(1));
        expect(find.text('개인정보 수집·이용'), findsOneWidget);
        expect(find.text('본인인증 정보'), findsOneWidget);
        expect(find.text('동의됨'), findsAtLeast(3));

        expect(find.widgetWithText(SwitchListTile, '서비스 이용약관'), findsNothing);
        expect(find.widgetWithText(SwitchListTile, '개인정보 수집·이용'), findsNothing);
        expect(find.widgetWithText(SwitchListTile, '본인인증 정보'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-1: 동의 항목 본문 시트 열람
  // ---------------------------------------------------------------------------
  cujGroup('2-1', '동의 항목 본문 시트 열람', () {
    cujCase(
      'happy: 필수 동의 타일 탭 시 ConsentDetailSheet 노출',
      app: const PrivacyPage(),
      overrides: base,
      body: (t) async {
        await t.tap(find.widgetWithText(ListTile, '서비스 이용약관').first);
        await t.pumpAndSettle();

        expect(
          find.text('서비스 이용을 위해 필요한 기본 권리와 의무를 안내합니다.'),
          findsOneWidget,
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-2: 약관 보기 섹션 ListTile 탭
  // ---------------------------------------------------------------------------
  cujGroup('2-2', '약관 보기 섹션 ListTile 탭', () {
    cujCase(
      'happy: 개인정보처리방침 탭 시 상세 시트 노출',
      app: const PrivacyPage(),
      overrides: base,
      body: (t) async {
        await t.scrollUntilVisible(find.text('개인정보처리방침'), 200);
        await t.tap(find.text('개인정보처리방침'));
        await t.pumpAndSettle();

        expect(find.text('밍릿의 개인정보 처리 방침을 안내합니다.'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-3: 본인인증 미완 상태 탭 무반응
  // ---------------------------------------------------------------------------
  cujGroup('2-3', '본인인증 미완 상태에서 본인인증 정보 탭', () {
    cujCase(
      'edge: 본인인증 미동의 상태에서는 시트가 열리지 않음',
      app: const PrivacyPage(),
      overrides: () {
        when(
          () => repo.getConsents('user-1'),
        ).thenAnswer((_) async => _baseConsents(identityVerified: false));
        return base();
      },
      body: (t) async {
        expect(find.text('미동의'), findsOneWidget);
        await t.tap(find.widgetWithText(ListTile, '본인인증 정보'));
        await t.pumpAndSettle();

        expect(find.text('본인인증(CI/DI) 수집 동의'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-1: 회원 탈퇴 시작 진입 (현재 구현 가드)
  // ---------------------------------------------------------------------------
  cujGroup('3-1', '회원 탈퇴 시작 진입', () {
    cujCase(
      'edge: PrivacyPage에서는 탈퇴 CTA 비노출 (#2093)',
      app: const PrivacyPage(),
      overrides: base,
      body: (t) async {
        expect(find.text('회원 탈퇴 시작하기'), findsNothing);
        expect(find.text('회원 탈퇴'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-2: 탈퇴 진행 중 재진입 sub-variant (현재 구현 가드)
  // ---------------------------------------------------------------------------
  cujGroup('3-2', '탈퇴 진행 중 재진입 시 sub-variant', () {
    cujCase(
      'edge: PrivacyPage에 탈퇴 진행 상태 카드 비노출',
      app: const PrivacyPage(),
      overrides: base,
      body: (t) async {
        expect(find.text('탈퇴 요청 진행 중'), findsNothing);
        expect(find.text('탈퇴 진행 상태 보기'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 4-1: (Phase 2) 인증 열람 권한 목록 노출 (미구현 가드)
  // ---------------------------------------------------------------------------
  cujGroup('4-1', '(Phase 2) 인증 열람 권한 목록 노출', () {
    cujCase(
      'edge: 현재 버전에서 인증 열람 현황 섹션 비노출',
      app: const PrivacyPage(),
      overrides: base,
      body: (t) async {
        expect(find.text('인증 열람 현황'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 4-2: (Phase 2) 만료 임박/만료됨 시각 분기 (미구현 가드)
  // ---------------------------------------------------------------------------
  cujGroup('4-2', '(Phase 2) 만료 임박 / 만료됨 시각 분기', () {
    cujCase(
      'edge: 만료 임박/만료됨 D-day UI 미노출',
      app: const PrivacyPage(),
      overrides: base,
      body: (t) async {
        expect(find.textContaining('곧 만료됩니다'), findsNothing);
        expect(find.textContaining('만료된 권한'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 4-3: (Phase 2) 빈 상태 (미구현 가드)
  // ---------------------------------------------------------------------------
  cujGroup('4-3', '(Phase 2) 빈 상태 (공유된 인증 없음)', () {
    cujCase(
      'edge: 빈 상태 문구 비노출',
      app: const PrivacyPage(),
      overrides: base,
      body: (t) async {
        expect(find.text('공유된 인증이 없습니다'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 5-1: (Phase 2) 권한 철회 확인 다이얼로그 (미구현 가드)
  // ---------------------------------------------------------------------------
  cujGroup('5-1', '(Phase 2) 권한 철회 확인 다이얼로그', () {
    cujCase(
      'edge: 권한 철회 액션/다이얼로그 비노출',
      app: const PrivacyPage(),
      overrides: base,
      body: (t) async {
        expect(find.text('권한 철회'), findsNothing);
        expect(find.text('권한을 철회하시겠습니까?'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 5-2: (Phase 2) 철회 성공 후 갱신 (미구현 가드)
  // ---------------------------------------------------------------------------
  cujGroup('5-2', '(Phase 2) 권한 철회 성공 후 SnackBar + 목록 갱신', () {
    cujCase(
      'edge: 철회 성공 스낵바 문구 비노출',
      app: const PrivacyPage(),
      overrides: base,
      body: (t) async {
        expect(find.text('권한이 철회되었습니다'), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 6-1: Loading state
  // ---------------------------------------------------------------------------
  cujGroup('6-1', 'Loading state — 동의 정보 가져오는 중', () {
    late Completer<List<UserConsent>> loadingCompleter;

    cujCase(
      'happy: 초기 fetch 진행 중 중앙 로딩 인디케이터 노출',
      app: const PrivacyPage(),
      overrides: () {
        loadingCompleter = Completer<List<UserConsent>>();
        when(
          () => repo.getConsents('user-1'),
        ).thenAnswer((_) => loadingCompleter.future);
        return base();
      },
      afterPump: (t) async {
        await t.pump();
      },
      body: (t) async {
        expect(find.byType(MinglitCircularProgressIndicator), findsOneWidget);

        loadingCompleter.complete(_baseConsents(identityVerified: true));
        await t.pumpAndSettle();
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 6-2: Error state
  // ---------------------------------------------------------------------------
  cujGroup('6-2', 'Error state — 동의 정보 로드 실패', () {
    cujCase(
      'happy: 첫 fetch 실패 시 에러 메시지 노출',
      app: const PrivacyPage(),
      overrides: () {
        when(
          () => repo.getConsents('user-1'),
        ).thenThrow(Exception('network error'));
        return base();
      },
      body: (t) async {
        expect(find.text('동의 정보를 불러올 수 없습니다.'), findsOneWidget);
      },
    );
  });
}
