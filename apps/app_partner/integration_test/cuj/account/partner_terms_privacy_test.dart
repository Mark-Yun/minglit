// CUJ tests — account / partner-terms-privacy (app_partner)
//
// 대응 spec: docs/features/account/partner-terms-privacy/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가.
//
// 커버리지 범위 (Flutter integration test):
//   1-1: 이용약관 타일 노출 + launchUrl(termsUrl) 호출 확인
//   2-1: 개인정보처리방침 타일 노출 + launchUrl(privacyUrl) 호출 확인
//
// Flutter 범위 외 CUJ (landing_partner 웹 기능 또는 미구현):
//   1-2, 1-3, 2-2, 2-3, 2-4, 3-1, 3-2 — cuj_coverage.dart 에서 미커버 표시됨.
//   웹 CUJ 는 landing_partner e2e 테스트로 커버해야 함.

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
  // 미커버 CUJ (landing_partner 웹 기능 또는 미구현) — Flutter 범위 외
  //
  // 1-2: /terms 앵커 스크롤 (landing_partner 웹)
  // 1-3: 파트너 등록 약관 동의 체크박스 (미구현)
  // 2-2: /privacy 국외이전 챕터 (landing_partner 웹)
  // 2-3: /privacy 처리위탁·제3자 (landing_partner 웹)
  // 2-4: /privacy 자동화된 결정 거부권 (landing_partner 웹)
  // 3-1: /privacy 필수 기재사항 13개 검수 (landing_partner 웹)
  // 3-2: footer 시행일자 (landing_partner 웹)
  //
  // 웹 CUJ 는 landing_partner e2e 테스트에서 커버해야 합니다.
  // ---------------------------------------------------------------------------
}
