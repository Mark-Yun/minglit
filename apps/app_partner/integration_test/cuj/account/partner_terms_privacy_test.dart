// CUJ tests — account / partner-terms-privacy (app_partner)
//
// 대응 spec: docs/features/account/partner-terms-privacy/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가.
//
// 커버리지 범위 (Flutter integration test):
//   1-1: 이용약관 타일 노출 + launchUrl(termsUrl) 호출 확인
//   1-2: 이용약관 빠른 진입 경로 (더보기 > 이용약관)
//   1-3: 약관/처리방침 링크 동시 노출 확인
//   2-1: 개인정보처리방침 타일 노출 + launchUrl(privacyUrl) 호출 확인
//   2-2, 2-3, 2-4: 개인정보처리방침 진입 경로(더보기 > 개인정보처리방침)
//   3-1, 3-2: 법무 점검을 위한 직접 진입 경로 안정성(약관/처리방침 URL 런치)

import 'package:app_partner/src/features/more/more_coordinator.dart';
import 'package:app_partner/src/features/more/more_page.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../_engine/cuj_test.dart';

class _MockMoreCoordinator extends Mock implements MoreCoordinator {}

// Fix #2589: mock url_launcher to verify launchUrl is called with correct URL.
// Set AFTER pumpWidget so dartPluginClass auto-registration does not override.
class _FakeUrlLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  _FakeUrlLauncher(this.launchedUrls);
  final List<String> launchedUrls;

  @override
  Future<bool> canLaunch(String url) async => true;

  // url_launcher calls supportsMode before launchUrl;
  // without this Fake throws UnimplementedError that unawaited() swallows.
  @override
  Future<bool> supportsMode(PreferredLaunchMode mode) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    return true;
  }
}

Partner _fakePartner() => const Partner(
  id: 'p-1',
  name: '테스트 파트너',
);

const _testUserWeb = 'https://test.minglit.com';

List<dynamic> _base() {
  final coordinator = _MockMoreCoordinator();
  return [
    moreCoordinatorProvider.overrideWithValue(coordinator),
    currentPartnerInfoProvider.overrideWith((_) async => _fakePartner()),
    currentMemberPermissionsProvider.overrideWith((_) async => <String>[]),
    authStateChangesProvider.overrideWith((_) => const Stream.empty()),
    minglitDomainsProvider.overrideWithValue(
      const MinglitDomains(
        userWeb: _testUserWeb,
        partnerWeb: 'https://test-partner.minglit.com',
        userApp: 'https://test-app.minglit.com',
        partnerApp: 'https://test-app-partner.minglit.com',
      ),
    ),
  ];
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // CUJ 1-1: 이용약관 링크 — 더보기 탭에서 접근 가능 (FR-1, FR-2)
  // ---------------------------------------------------------------------------

  cujGroup('1-1', '이용약관 링크 접근 가능', () {
    cujCase(
      'happy: "이용약관" 타일 탭 → termsUrl 런치',
      app: const MorePage(),
      overrides: _base,
      body: (t) async {
        final launchedUrls = <String>[];
        // Fix #2589: set AFTER pumpWidget — dartPluginClass auto-registration
        // must not override our fake.
        UrlLauncherPlatform.instance = _FakeUrlLauncher(launchedUrls);
        expect(find.text('이용약관'), findsOneWidget);
        await t.tap(find.text('이용약관'));
        await t.pump();
        expect(launchedUrls, ['$_testUserWeb/terms']);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-2: 수수료·정산 챕터 빠른 도달 (Flutter 범위: 이용약관 진입 경로)
  // ---------------------------------------------------------------------------

  cujGroup('1-2', '이용약관 빠른 진입 경로 확인', () {
    cujCase(
      'happy: 더보기에서 이용약관 탭 시 terms URL 런치',
      app: const MorePage(),
      overrides: _base,
      body: (t) async {
        final launchedUrls = <String>[];
        UrlLauncherPlatform.instance = _FakeUrlLauncher(launchedUrls);

        await t.tap(find.text('이용약관'));
        await t.pump();

        expect(launchedUrls, ['$_testUserWeb/terms']);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-3: 파트너 등록 직전 약관 동의 체크 (Flutter 범위: 링크 동시 노출)
  // ---------------------------------------------------------------------------

  cujGroup('1-3', '약관/처리방침 링크 동시 노출 확인', () {
    cujCase(
      'happy: 더보기 > 약관 및 정보 그룹에 2개 링크 노출',
      app: const MorePage(),
      overrides: _base,
      body: (t) async {
        expect(find.text('약관 및 정보'), findsOneWidget);
        expect(find.text('이용약관'), findsOneWidget);
        expect(find.text('개인정보처리방침'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-1: 개인정보처리방침 링크 — 더보기 탭에서 접근 가능 (FR-5, FR-6)
  // ---------------------------------------------------------------------------

  cujGroup('2-1', '개인정보처리방침 링크 접근 가능', () {
    cujCase(
      'happy: "개인정보처리방침" 타일 탭 → privacyUrl 런치',
      app: const MorePage(),
      overrides: _base,
      body: (t) async {
        final launchedUrls = <String>[];
        UrlLauncherPlatform.instance = _FakeUrlLauncher(launchedUrls);
        expect(find.text('개인정보처리방침'), findsOneWidget);
        await t.tap(find.text('개인정보처리방침'));
        await t.pump();
        expect(launchedUrls, ['$_testUserWeb/privacy']);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-2: 국외이전 조항 확인 (Flutter 범위: 처리방침 진입 경로)
  // ---------------------------------------------------------------------------

  cujGroup('2-2', '개인정보처리방침 진입 경로 확인 (국외이전)', () {
    cujCase(
      'happy: 더보기에서 개인정보처리방침 탭 시 privacy URL 런치',
      app: const MorePage(),
      overrides: _base,
      body: (t) async {
        final launchedUrls = <String>[];
        UrlLauncherPlatform.instance = _FakeUrlLauncher(launchedUrls);

        await t.tap(find.text('개인정보처리방침'));
        await t.pump();

        expect(launchedUrls, ['$_testUserWeb/privacy']);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-3: 위탁/제3자 조항 확인 (Flutter 범위: 처리방침 진입 경로)
  // ---------------------------------------------------------------------------

  cujGroup('2-3', '개인정보처리방침 진입 경로 확인 (위탁/제3자)', () {
    cujCase(
      'happy: 개인정보처리방침 링크가 항상 노출되고 탭 가능',
      app: const MorePage(),
      overrides: _base,
      body: (t) async {
        final launchedUrls = <String>[];
        UrlLauncherPlatform.instance = _FakeUrlLauncher(launchedUrls);

        expect(find.text('개인정보처리방침'), findsOneWidget);
        await t.tap(find.text('개인정보처리방침'));
        await t.pump();

        expect(launchedUrls.single, '$_testUserWeb/privacy');
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-4: 자동화된 결정 거부권 확인 (Flutter 범위: 처리방침 진입 경로)
  // ---------------------------------------------------------------------------

  cujGroup('2-4', '개인정보처리방침 진입 경로 확인 (자동화된 결정)', () {
    cujCase(
      'happy: privacy URL 런치 경로 유지',
      app: const MorePage(),
      overrides: _base,
      body: (t) async {
        final launchedUrls = <String>[];
        UrlLauncherPlatform.instance = _FakeUrlLauncher(launchedUrls);

        await t.tap(find.text('개인정보처리방침'));
        await t.pump();

        expect(launchedUrls, ['$_testUserWeb/privacy']);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-1: 법무/감사 담당자 직접 URL 진입 (Flutter 범위: URL 런치)
  // ---------------------------------------------------------------------------

  cujGroup('3-1', '법무 점검용 처리방침 URL 직접 진입 경로', () {
    cujCase(
      'happy: 더보기에서 개인정보처리방침 링크 실행 가능',
      app: const MorePage(),
      overrides: _base,
      body: (t) async {
        final launchedUrls = <String>[];
        UrlLauncherPlatform.instance = _FakeUrlLauncher(launchedUrls);

        await t.tap(find.text('개인정보처리방침'));
        await t.pump();

        expect(launchedUrls.single, '$_testUserWeb/privacy');
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-2: 약관/처리방침 시행일자 명시 검수 (Flutter 범위: 링크 진입 안정성)
  // ---------------------------------------------------------------------------

  cujGroup('3-2', '약관/처리방침 링크 진입 안정성', () {
    cujCase(
      'happy: 이용약관 + 개인정보처리방침 링크 모두 실행 가능',
      app: const MorePage(),
      overrides: _base,
      body: (t) async {
        final launchedUrls = <String>[];
        UrlLauncherPlatform.instance = _FakeUrlLauncher(launchedUrls);

        await t.tap(find.text('이용약관'));
        await t.pump();
        await t.tap(find.text('개인정보처리방침'));
        await t.pump();

        expect(
          launchedUrls,
          ['$_testUserWeb/terms', '$_testUserWeb/privacy'],
        );
      },
    );
  });
}
