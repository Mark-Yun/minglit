// CUJ tests — account / login-dark-theme (app_user)
//
// 대응 spec: docs/features/account/login-dark-theme/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가 (새 파일 X).
//
// 커버 범위 (Flutter integration test):
//   1-1, 1-2, 1-3, 1-4, 2-1: 다크/라이트 모드 렌더링 + 버튼 구조 검증
//   3-1: 로그인 화면 렌더 확인 (redirect 깜빡임은 시각적 golden 테스트 범위)
//   5-1: 실행 중 시스템 테마 토글 시 즉시 반영 (StatefulWrapper 패턴)
//
// 색상 정확도 (NFR-5/NFR-6, Fix #1542):
//   픽셀 수준 색상 검증은 test/widget/ 에 위치한 golden 테스트가 담당.
//   본 CUJ 테스트는 어두운/밝은 테마에서 구조 + 콜백 동작을 검증.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/cuj_test.dart';

const _fakeDomains = MinglitDomains(
  userWeb: 'https://test.minglit.com',
  partnerWeb: 'https://test-partner.minglit.com',
  userApp: 'https://test-app.minglit.com',
  partnerApp: 'https://test-app-partner.minglit.com',
);

List<dynamic> _base() => [
  minglitDomainsProvider.overrideWithValue(_fakeDomains),
];

// CUJ 5-1: StatefulWidget for simulating system theme toggle.
class _ThemeWrapper extends StatefulWidget {
  const _ThemeWrapper();

  @override
  State<_ThemeWrapper> createState() => _ThemeWrapperState();
}

class _ThemeWrapperState extends State<_ThemeWrapper> {
  bool _isDark = false;

  void setDark({required bool value}) {
    setState(() => _isDark = value);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isDark
          ? MinglitTheme.materialThemeDark
          : MinglitTheme.materialTheme,
      child: const MinglitLoginScreen(),
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // CUJ 1-1: 다크 모드 진입 시 Scaffold 배경 일관
  // ---------------------------------------------------------------------------

  cujGroup('1-1', '다크 모드 진입 시 Scaffold 배경 일관', () {
    cujCase(
      'happy: 다크 테마에서 Scaffold 렌더 + brightness == Brightness.dark',
      app: Theme(
        data: MinglitTheme.materialThemeDark,
        child: const MinglitLoginScreen(),
      ),
      overrides: _base,
      body: (t) async {
        expect(find.byType(Scaffold), findsOneWidget);

        // Fix #1542: 다크 모드에서 Scaffold 배경이 테마를 따름 확인
        final scaffold = t.element(find.byType(Scaffold));
        expect(Theme.of(scaffold).brightness, equals(Brightness.dark));

        // OAuth 버튼 존재 확인
        expect(find.text('Google로 시작하기'), findsOneWidget);
        expect(find.text('Kakao로 시작하기'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-2: 다크 모드에서 Google 버튼 다크 변형
  // ---------------------------------------------------------------------------

  cujGroup('1-2', '다크 모드에서 Google 버튼 다크 변형', () {
    var googleCalled = false;

    cujCase(
      'happy: 다크 모드 Google 버튼 존재 + 탭 가능 (다크 변형 렌더 확인)',
      app: Theme(
        data: MinglitTheme.materialThemeDark,
        child: MinglitLoginScreen(
          onGoogleSignIn: () => googleCalled = true,
          onKakaoSignIn: () {},
        ),
      ),
      overrides: _base,
      body: (t) async {
        googleCalled = false;

        // 다크 모드에서 Google 버튼 렌더 확인 (FR-2)
        expect(find.text('Google로 시작하기'), findsOneWidget);

        await t.tap(find.text('Google로 시작하기'));
        await t.pumpAndSettle();

        expect(googleCalled, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-3: 다크 모드에서 Apple 버튼 white-on-dark 변형
  // ---------------------------------------------------------------------------

  cujGroup('1-3', '다크 모드에서 Apple 버튼 white-on-dark 변형', () {
    cujCase(
      'happy: iOS/macOS 다크 모드 — Apple 버튼 렌더 (white-on-dark)',
      app: Theme(
        data: MinglitTheme.materialThemeDark,
        child: MinglitLoginScreen(
          onGoogleSignIn: () {},
          onAppleSignIn: () {},
          onKakaoSignIn: () {},
        ),
      ),
      overrides: _base,
      body: (t) async {
        // Fix #1542: 다크 모드에서 Apple 버튼 존재 확인 (FR-3 — white-on-dark 변형)
        expect(find.text('Apple로 시작하기'), findsOneWidget);

        // 다크 테마 적용 확인
        final scaffold = t.element(find.byType(Scaffold));
        expect(Theme.of(scaffold).brightness, equals(Brightness.dark));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 1-4: 다크 모드에서 Kakao 노랑 고정
  // ---------------------------------------------------------------------------

  cujGroup('1-4', '다크 모드에서 Kakao 노랑 고정', () {
    var kakaoCalled = false;

    cujCase(
      'happy: 다크 모드에서 Kakao 버튼 렌더 + 탭 가능 (브랜드 고정)',
      app: Theme(
        data: MinglitTheme.materialThemeDark,
        child: MinglitLoginScreen(
          onGoogleSignIn: () {},
          onKakaoSignIn: () => kakaoCalled = true,
        ),
      ),
      overrides: _base,
      body: (t) async {
        kakaoCalled = false;

        // Fix #1542: 다크 모드에서도 Kakao 버튼 존재 확인 (FR-4)
        expect(find.text('Kakao로 시작하기'), findsOneWidget);

        await t.tap(find.text('Kakao로 시작하기'));
        await t.pumpAndSettle();

        expect(kakaoCalled, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 2-1: 라이트 모드 baseline (회귀 없음)
  // ---------------------------------------------------------------------------

  cujGroup('2-1', '라이트 모드 baseline (회귀 없음)', () {
    cujCase(
      'happy: 라이트 모드 — Google + Apple + Kakao 버튼 존재 (FR-1~4 baseline)',
      app: MinglitLoginScreen(
        onGoogleSignIn: () {},
        onAppleSignIn: () {},
        onKakaoSignIn: () {},
      ),
      overrides: _base,
      body: (t) async {
        expect(find.byType(Scaffold), findsOneWidget);

        // 라이트 테마 확인
        final scaffold = t.element(find.byType(Scaffold));
        expect(Theme.of(scaffold).brightness, equals(Brightness.light));

        // 모든 OAuth 버튼 존재 확인 (회귀 없음)
        expect(find.text('Google로 시작하기'), findsOneWidget);
        expect(find.text('Apple로 시작하기'), findsOneWidget);
        expect(find.text('Kakao로 시작하기'), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 3-1: 보호 경로 redirect 시 깜빡임 제거
  // ---------------------------------------------------------------------------

  cujGroup('3-1', '보호 경로 redirect 시 깜빡임 제거', () {
    cujCase(
      'happy: 다크 모드 로그인 화면 렌더 — 깜빡임 없는 초기 상태 확인',
      app: Theme(
        data: MinglitTheme.materialThemeDark,
        child: const MinglitLoginScreen(),
      ),
      overrides: _base,
      body: (t) async {
        // Fix #1542: redirect 도착 시 Scaffold 배경 = 다크 테마 (깜빡임 없이)
        // 전체 routing 시뮬레이션은 routing integration test 범위 — 여기선
        // 로그인 화면이 다크 모드에서 올바르게 렌더됨을 확인.
        final scaffold = t.element(find.byType(Scaffold));
        expect(Theme.of(scaffold).brightness, equals(Brightness.dark));
        expect(find.byType(Scaffold), findsOneWidget);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // CUJ 5-1: 실행 중 시스템 테마 토글 시 즉시 반영
  // ---------------------------------------------------------------------------

  cujGroup('5-1', '실행 중 시스템 테마 토글 시 즉시 반영', () {
    cujCase(
      'happy: 라이트→다크 토글 → 로그인 화면 즉시 다크 변형 교체',
      app: const _ThemeWrapper(),
      overrides: _base,
      body: (t) async {
        // 초기 라이트 모드 확인
        final wrapperEl = t.element(find.byType(_ThemeWrapper));
        expect(Theme.of(wrapperEl).brightness, equals(Brightness.light));

        // 시스템 테마 토글 시뮬레이션 (OS 이벤트 → setState)
        t
            .state<_ThemeWrapperState>(find.byType(_ThemeWrapper))
            .setDark(value: true);
        await t.pump();

        // 즉시 다크 변형 교체 확인 (재진입 불필요)
        final updatedEl = t.element(find.byType(_ThemeWrapper));
        expect(Theme.of(updatedEl).brightness, equals(Brightness.dark));
      },
    );
  });
}
