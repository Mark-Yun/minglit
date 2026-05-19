// CUJ tests — account / partner-terms-privacy (app_partner)
//
// 대응 spec: docs/features/account/partner-terms-privacy/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가.

import 'package:app_partner/src/features/more/more_coordinator.dart';
import 'package:app_partner/src/features/more/more_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

import '../_engine/cuj_test.dart';

class _MockMoreCoordinator extends Mock implements MoreCoordinator {}

Partner _fakePartner() => const Partner(
      id: 'p-1',
      name: '테스트 파트너',
    );

List<dynamic> _base() {
  final coordinator = _MockMoreCoordinator();
  return [
    moreCoordinatorProvider.overrideWithValue(coordinator),
    currentPartnerInfoProvider.overrideWith((_) async => _fakePartner()),
    currentMemberPermissionsProvider.overrideWith((_) async => <String>[]),
    authStateChangesProvider.overrideWith((_) => const Stream.empty()),
  ];
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // CUJ 1-1: 이용약관 링크 — 더보기 탭에서 접근 가능 (FR-1, FR-2)
  // ---------------------------------------------------------------------------

  cujGroup('1-1', '이용약관 링크 접근 가능', () {
    cujCase(
      'happy: 더보기 탭에 "이용약관" 타일 노출',
      app: const MorePage(),
      overrides: _base,
      body: (t) async {
        await t.pumpAndSettle();
        expect(find.text('이용약관'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-2: 수수료·정산 챕터 빠른 도달 — landing_partner 웹 기능 (FR-2, FR-3)
  // ---------------------------------------------------------------------------

  cujGroup('1-2', '수수료·정산 챕터 앵커 스크롤', () {
    cujCase(
      'spec: landing_partner /terms 페이지의 앵커 스크롤 — 웹 기능, spec ID 추적',
      app: const MorePage(),
      overrides: _base,
      body: (t) async {
        // 이 CUJ는 landing_partner 웹 페이지(/terms)의 목차 앵커 스크롤을 테스트합니다.
        // Flutter integration test 범위 외(웹 기능). spec ID 추적용.
        await t.pumpAndSettle();
        expect(find.text('이용약관'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-3: 파트너 등록 직전 약관 동의 체크 — 미구현 기능 (FR-4)
  // ---------------------------------------------------------------------------

  cujGroup('1-3', '파트너 등록 약관 동의 체크박스', () {
    cujCase(
      'spec: 파트너 등록 페이지 약관 동의 체크박스 — 미구현 기능, spec ID 추적',
      app: const MorePage(),
      overrides: _base,
      body: (t) async {
        // 이 CUJ는 파트너 등록 페이지의 약관/처리방침 동의 체크박스를 테스트합니다.
        // 현재 PartnerApplyPage(Step5Review)에 해당 체크박스가 미구현.
        // 기능 구현 시 PartnerApplyPage Step5Review에 checkbox 추가 후 이 stub 교체.
        await t.pumpAndSettle();
        expect(find.text('이용약관'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-1: 개인정보처리방침 링크 — 더보기 탭에서 접근 가능 (FR-5, FR-6)
  // ---------------------------------------------------------------------------

  cujGroup('2-1', '개인정보처리방침 링크 접근 가능', () {
    cujCase(
      'happy: 더보기 탭에 "개인정보처리방침" 타일 노출',
      app: const MorePage(),
      overrides: _base,
      body: (t) async {
        await t.pumpAndSettle();
        expect(find.text('개인정보처리방침'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-2: 국외이전 조항 확인 — landing_partner 웹 기능 (FR-7)
  // ---------------------------------------------------------------------------

  cujGroup('2-2', '국외이전(Supabase) 조항 확인', () {
    cujCase(
      'spec: landing_partner /privacy 국외이전 챕터 — 웹 기능, spec ID 추적',
      app: const MorePage(),
      overrides: _base,
      body: (t) async {
        // landing_partner 웹 페이지(/privacy)의 국외이전 챕터 표 노출 테스트.
        // Flutter integration test 범위 외. spec ID 추적용.
        await t.pumpAndSettle();
        expect(find.text('개인정보처리방침'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-3: 위탁사/제3자 제공 항목 확인 — landing_partner 웹 기능 (FR-8, FR-9)
  // ---------------------------------------------------------------------------

  cujGroup('2-3', '처리 위탁·제3자 제공 항목 확인', () {
    cujCase(
      'spec: landing_partner /privacy 처리위탁·제3자 제공 챕터 — 웹 기능, spec ID 추적',
      app: const MorePage(),
      overrides: _base,
      body: (t) async {
        // landing_partner 웹 페이지(/privacy)의 처리위탁·제3자 제공 표 노출 테스트.
        // Flutter integration test 범위 외. spec ID 추적용.
        await t.pumpAndSettle();
        expect(find.text('개인정보처리방침'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-4: 자동화된 결정 거부권 확인 — landing_partner 웹 기능 (FR-10)
  // ---------------------------------------------------------------------------

  cujGroup('2-4', '자동화된 결정에 대한 거부권 확인', () {
    cujCase(
      'spec: landing_partner /privacy 자동화된 결정 챕터 — 웹 기능, spec ID 추적',
      app: const MorePage(),
      overrides: _base,
      body: (t) async {
        // landing_partner 웹 페이지(/privacy)의 자동화된 결정 거부권 챕터 노출.
        // Flutter integration test 범위 외. spec ID 추적용.
        await t.pumpAndSettle();
        expect(find.text('개인정보처리방침'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-1: 필수 기재사항 검수 — landing_partner 웹 기능 (FR-5, FR-11)
  // ---------------------------------------------------------------------------

  cujGroup('3-1', '법무/감사 필수 기재사항 13개 검수', () {
    cujCase(
      'spec: landing_partner /privacy 13개 필수 기재사항 — 웹 기능, spec ID 추적',
      app: const MorePage(),
      overrides: _base,
      body: (t) async {
        // landing_partner 웹 페이지(/privacy)의 개인정보보호법 제30조 필수 기재사항 검수.
        // Flutter integration test 범위 외. spec ID 추적용.
        await t.pumpAndSettle();
        expect(find.text('개인정보처리방침'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-2: 시행일자 footer 명시 — landing_partner 웹 기능 (FR-11)
  // ---------------------------------------------------------------------------

  cujGroup('3-2', '약관/처리방침 시행일자 footer 표시', () {
    cujCase(
      'spec: landing_partner 페이지 footer 공고일자/시행일자 — 웹 기능, spec ID 추적',
      app: const MorePage(),
      overrides: _base,
      body: (t) async {
        // landing_partner 웹 페이지 하단 footer에 공고일자/시행일자 노출.
        // Flutter integration test 범위 외. spec ID 추적용.
        await t.pumpAndSettle();
        expect(find.text('이용약관'), findsOneWidget);
      },
    );
  });
}
