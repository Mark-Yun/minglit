// CUJ tests — account / login-dark-theme
//
// 대응 spec: docs/features/account/login-dark-theme/spec.md
// CUJ 추가 시 본 파일에 `cujGroup` 블록 추가.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

import '../_engine/cuj_test.dart';

const _loginRouteMarkerKey = ValueKey<String>('login-route-marker');

class _ThemeHost extends StatelessWidget {
  const _ThemeHost({
    required this.mode,
    required this.child,
  });

  final ThemeMode mode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        theme: MinglitTheme.materialTheme,
        darkTheme: MinglitTheme.materialThemeDark,
        themeMode: mode,
        home: child,
      ),
    );
  }
}

class _RuntimeToggleHost extends StatelessWidget {
  const _RuntimeToggleHost({
    required this.mode,
  });

  final ValueNotifier<ThemeMode> mode;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: mode,
      builder: (context, themeMode, _) {
        return ProviderScope(
          child: MaterialApp(
            theme: MinglitTheme.materialTheme,
            darkTheme: MinglitTheme.materialThemeDark,
            themeMode: themeMode,
            home: _loginScreen(),
          ),
        );
      },
    );
  }
}

class _RedirectEntryPage extends StatelessWidget {
  const _RedirectEntryPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: () => context.go('/my'),
          child: const Text('보호 화면 진입'),
        ),
      ),
    );
  }
}

class _AuthRedirectRouterHost extends StatefulWidget {
  const _AuthRedirectRouterHost({required this.mode});

  final ValueNotifier<ThemeMode> mode;

  @override
  State<_AuthRedirectRouterHost> createState() =>
      _AuthRedirectRouterHostState();
}

class _AuthRedirectRouterHostState extends State<_AuthRedirectRouterHost> {
  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const _RedirectEntryPage(),
      ),
      GoRoute(
        path: '/my',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => KeyedSubtree(
          key: _loginRouteMarkerKey,
          child: _loginScreen(),
        ),
      ),
    ],
    redirect: (context, state) {
      if (state.uri.path == '/my') {
        return Uri(
          path: '/login',
          queryParameters: const <String, String>{'from': '/my'},
        ).toString();
      }
      return null;
    },
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: widget.mode,
      builder: (context, themeMode, _) {
        return ProviderScope(
          child: MaterialApp.router(
            theme: MinglitTheme.materialTheme,
            darkTheme: MinglitTheme.materialThemeDark,
            themeMode: themeMode,
            routerConfig: _router,
          ),
        );
      },
    );
  }
}

Widget _loginScreen({bool showApple = true}) {
  return MinglitLoginScreen(
    onGoogleSignIn: _noop,
    onAppleSignIn: showApple ? _noop : null,
    onKakaoSignIn: _noop,
  );
}

OutlinedButton _button(WidgetTester tester, String label) {
  return tester.widget<OutlinedButton>(
    find.widgetWithText(OutlinedButton, label),
  );
}

Color _buttonBackground(OutlinedButton button) {
  return button.style!.backgroundColor!.resolve(<WidgetState>{})!;
}

Color _buttonForeground(OutlinedButton button) {
  return button.style!.foregroundColor!.resolve(<WidgetState>{})!;
}

Color _buttonBorder(OutlinedButton button) {
  return button.style!.side!.resolve(<WidgetState>{})!.color;
}

Color _canvasMaterialColor(WidgetTester tester) {
  final materials = tester.widgetList<Material>(find.byType(Material));
  final canvas = materials.firstWhere(
    (material) =>
        material.type == MaterialType.canvas && material.color != null,
  );
  return canvas.color!;
}

void _noop() {}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxFrames = 12,
}) async {
  for (var i = 0; i < maxFrames; i++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  cujGroup('1-1', '다크 모드 진입 시 Scaffold 배경 일관', () {
    cujCase(
      'happy: 다크 모드에서 로그인 화면 배경이 dark background로 렌더',
      app: _ThemeHost(mode: ThemeMode.dark, child: _loginScreen()),
      body: (t) async {
        expect(_canvasMaterialColor(t), MinglitColorsDark.background);
      },
    );

    cujCase(
      'edge: 다크 모드에서도 wallpaper/동적 색 영향 없이 동일 배경 유지',
      app: _ThemeHost(mode: ThemeMode.dark, child: _loginScreen()),
      body: (t) async {
        final firstFrameColor = _canvasMaterialColor(t);
        await t.pump(const Duration(milliseconds: 50));
        expect(firstFrameColor, MinglitColorsDark.background);
        expect(_canvasMaterialColor(t), firstFrameColor);
      },
    );
  });

  cujGroup('1-2', '다크 모드에서 Google 버튼 다크 변형', () {
    cujCase(
      'happy: Google 버튼이 다크 배경 + 가독성 높은 글자색으로 렌더',
      app: _ThemeHost(mode: ThemeMode.dark, child: _loginScreen()),
      body: (t) async {
        final google = _button(t, 'Google로 시작하기');
        final darkTheme = MinglitTheme.materialThemeDark;

        expect(_buttonBackground(google), MinglitColorsDark.surface);
        expect(
          _buttonForeground(google),
          darkTheme.colorScheme.onSurface.withValues(
            alpha: MinglitOpacity.highEmphasis,
          ),
        );
      },
    );

    cujCase(
      'edge: Google 버튼 border가 outlineVariant 토큰을 사용',
      app: _ThemeHost(mode: ThemeMode.dark, child: _loginScreen()),
      body: (t) async {
        final google = _button(t, 'Google로 시작하기');
        expect(
          _buttonBorder(google),
          MinglitTheme.materialThemeDark.colorScheme.outlineVariant,
        );
      },
    );
  });

  cujGroup('1-3', '다크 모드에서 Apple 버튼 white-on-dark 변형', () {
    cujCase(
      'happy: Apple 버튼이 white-on-dark 색상 조합으로 렌더',
      app: _ThemeHost(
        mode: ThemeMode.dark,
        child: _loginScreen(),
      ),
      body: (t) async {
        final apple = _button(t, 'Apple로 시작하기');

        expect(_buttonBackground(apple), MinglitColors.background);
        expect(_buttonForeground(apple), MinglitColors.textPrimary);
      },
    );

    cujCase(
      'edge: Apple 버튼 콜백 미제공 시 버튼 비노출(비지원 플랫폼 정책)',
      app: _ThemeHost(
        mode: ThemeMode.dark,
        child: _loginScreen(showApple: false),
      ),
      body: (t) async {
        expect(
          find.widgetWithText(OutlinedButton, 'Apple로 시작하기'),
          findsNothing,
        );
      },
    );
  });

  cujGroup('1-4', '다크 모드에서 Kakao 노랑 고정', () {
    cujCase(
      'happy: Kakao 버튼은 다크 모드에서도 브랜드 노랑/검정 글자 유지',
      app: _ThemeHost(mode: ThemeMode.dark, child: _loginScreen()),
      body: (t) async {
        final kakao = _button(t, 'Kakao로 시작하기');

        expect(_buttonBackground(kakao), MinglitColors.warning);
        expect(
          _buttonForeground(kakao),
          MinglitColors.textPrimary.withValues(
            alpha: MinglitOpacity.highEmphasis,
          ),
        );
      },
    );

    cujCase(
      'edge: 라이트↔다크 모드 전환과 무관하게 Kakao 색상 고정',
      app: _RuntimeToggleHost(mode: ValueNotifier<ThemeMode>(ThemeMode.light)),
      body: (t) async {
        final mode = ValueNotifier<ThemeMode>(ThemeMode.light);
        await t.pumpWidget(_RuntimeToggleHost(mode: mode));
        await t.pumpAndSettle();

        final lightButton = _button(t, 'Kakao로 시작하기');
        final lightBg = _buttonBackground(lightButton);
        final lightFg = _buttonForeground(lightButton);

        mode.value = ThemeMode.dark;
        await t.pumpAndSettle();

        final darkButton = _button(t, 'Kakao로 시작하기');
        expect(_buttonBackground(darkButton), lightBg);
        expect(_buttonForeground(darkButton), lightFg);
      },
    );
  });

  cujGroup('2-1', '라이트 모드 baseline (회귀 없음)', () {
    cujCase(
      'happy: 라이트 모드에서 기존 버튼/배경 baseline 유지',
      app: _ThemeHost(mode: ThemeMode.light, child: _loginScreen()),
      body: (t) async {
        final google = _button(t, 'Google로 시작하기');
        final apple = _button(t, 'Apple로 시작하기');
        final kakao = _button(t, 'Kakao로 시작하기');

        expect(_canvasMaterialColor(t), MinglitColors.surface);
        expect(_buttonBackground(google), MinglitColors.background);
        expect(_buttonBackground(apple), MinglitColors.textPrimary);
        expect(_buttonBackground(kakao), MinglitColors.warning);
      },
    );
  });

  cujGroup('3-1', '보호 경로 redirect 시 깜빡임 제거', () {
    cujCase(
      'happy: 다크 보호 화면에서 로그인 redirect 후 배경 톤 유지',
      app: const SizedBox.shrink(),
      body: (t) async {
        final mode = ValueNotifier<ThemeMode>(ThemeMode.dark);
        addTearDown(mode.dispose);
        await t.pumpWidget(_AuthRedirectRouterHost(mode: mode));
        await t.pumpAndSettle();

        expect(_canvasMaterialColor(t), MinglitColorsDark.background);

        await t.tap(find.text('보호 화면 진입'));
        await t.pump();

        // Redirect 첫 프레임에서 밝은 flash가 없어야 한다.
        expect(_canvasMaterialColor(t), MinglitColorsDark.background);

        await _pumpUntilFound(t, find.byKey(_loginRouteMarkerKey));
        expect(find.byKey(_loginRouteMarkerKey), findsOneWidget);
        expect(find.text('Google로 시작하기'), findsOneWidget);
        expect(_canvasMaterialColor(t), MinglitColorsDark.background);

        await t.pumpAndSettle();
        expect(_canvasMaterialColor(t), MinglitColorsDark.background);
      },
    );

    cujCase(
      'edge: redirect 직전에 테마 전환해도 로그인 도착 프레임의 배경 일치',
      app: const SizedBox.shrink(),
      body: (t) async {
        final mode = ValueNotifier<ThemeMode>(ThemeMode.dark);
        addTearDown(mode.dispose);
        await t.pumpWidget(_AuthRedirectRouterHost(mode: mode));
        await t.pumpAndSettle();

        mode.value = ThemeMode.light;
        await t.pumpAndSettle();

        await t.tap(find.text('보호 화면 진입'));
        await t.pump();
        expect(_canvasMaterialColor(t), MinglitColors.surface);
        await _pumpUntilFound(t, find.byKey(_loginRouteMarkerKey));
        expect(find.byKey(_loginRouteMarkerKey), findsOneWidget);
        expect(find.text('Google로 시작하기'), findsOneWidget);
        expect(_canvasMaterialColor(t), MinglitColors.surface);

        await t.pumpAndSettle();

        expect(_canvasMaterialColor(t), MinglitColors.surface);
      },
    );
  });

  cujGroup('5-1', '실행 중 시스템 테마 토글 시 즉시 반영', () {
    cujCase(
      'happy: 로그인 화면 노출 중 themeMode 변경 시 즉시 색상 반영',
      app: _RuntimeToggleHost(mode: ValueNotifier<ThemeMode>(ThemeMode.light)),
      body: (t) async {
        final mode = ValueNotifier<ThemeMode>(ThemeMode.light);
        await t.pumpWidget(_RuntimeToggleHost(mode: mode));
        await t.pumpAndSettle();

        expect(_canvasMaterialColor(t), MinglitColors.surface);
        expect(
          _buttonBackground(_button(t, 'Google로 시작하기')),
          MinglitColors.background,
        );

        mode.value = ThemeMode.dark;
        await t.pumpAndSettle();

        expect(_canvasMaterialColor(t), MinglitColorsDark.background);
        expect(
          _buttonBackground(_button(t, 'Google로 시작하기')),
          MinglitColorsDark.surface,
        );
      },
    );

    cujCase(
      'edge: 토글 직후 재진입 없이 버튼 foreground도 새 테마로 즉시 교체',
      app: _RuntimeToggleHost(mode: ValueNotifier<ThemeMode>(ThemeMode.light)),
      body: (t) async {
        final mode = ValueNotifier<ThemeMode>(ThemeMode.light);
        await t.pumpWidget(_RuntimeToggleHost(mode: mode));
        await t.pumpAndSettle();

        mode.value = ThemeMode.dark;
        await t.pumpAndSettle();

        final google = _button(t, 'Google로 시작하기');
        expect(
          _buttonForeground(google),
          MinglitTheme.materialThemeDark.colorScheme.onSurface.withValues(
            alpha: MinglitOpacity.highEmphasis,
          ),
        );
      },
    );
  });
}
