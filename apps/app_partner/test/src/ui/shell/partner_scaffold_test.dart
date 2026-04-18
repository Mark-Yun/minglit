import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:app_partner/src/ui/shell/partner_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Fake [StatefulNavigationShell] for testing bottom navigation rendering.
class _FakeNavigationShell extends StatefulWidget
    implements StatefulNavigationShell {
  const _FakeNavigationShell({this.currentIdx = 0});

  final int currentIdx;

  @override
  int get currentIndex => currentIdx;

  @override
  State<_FakeNavigationShell> createState() => _FakeNavigationShellState();

  // --- StatefulNavigationShell stubs (unused in render tests) ---

  @override
  void goBranch(int index, {bool initialLocation = false}) {}

  Widget get child => throw UnimplementedError();

  @override
  ShellRouteContext get shellRouteContext => throw UnimplementedError();

  @override
  StatefulShellRoute get route => throw UnimplementedError();

  @override
  ShellNavigationContainerBuilder get containerBuilder =>
      throw UnimplementedError();

  @override
  List<StatefulShellBranch> get debugLoadedBranches =>
      throw UnimplementedError();
}

class _FakeNavigationShellState extends State<_FakeNavigationShell> {
  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Shell Content'));
}

void main() {
  Widget buildSubject({
    int currentIndex = 0,
    bool hasSettlementAccess = true,
  }) {
    // Wrap with a Router to provide GoRouterState via InheritedWidget.
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => PartnerScaffold(
            navigationShell: _FakeNavigationShell(currentIdx: currentIndex),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        // Fix #1533: 테스트에서 hasSettlementAccessProvider를 오버라이드해
        // 권한 기반 탭 가시성 동작을 제어.
        hasSettlementAccessProvider.overrideWith(
          (ref) => Future.value(hasSettlementAccess),
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('PartnerScaffold bottom navigation — owner (settlement access)', () {
    testWidgets('renders 5 navigation destinations', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(NavigationDestination), findsNWidgets(5));
    });

    testWidgets('renders correct labels for all 5 tabs', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('홈'), findsOneWidget);
      expect(find.text('신청관리'), findsOneWidget);
      expect(find.text('체크인'), findsOneWidget);
      expect(find.text('정산'), findsOneWidget);
      expect(find.text('더보기'), findsOneWidget);
    });

    testWidgets('selectedIndex defaults to 0 (홈)', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 0);
    });

    testWidgets('selectedIndex reflects currentIndex 2 (체크인)', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(currentIndex: 2));
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 2);
    });

    testWidgets('selectedIndex reflects currentIndex 4 (더보기)', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(currentIndex: 4));
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 4);
    });

    testWidgets('renders shell content in body', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Shell Content'), findsOneWidget);
    });
  });

  // Fix #1533: 정산 탭 권한 기반 가시성 — 회귀 방지 테스트.
  group('PartnerScaffold bottom navigation — staff (no settlement access)', () {
    testWidgets('renders 4 navigation destinations (settlement hidden)', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(hasSettlementAccess: false));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationDestination), findsNWidgets(4));
    });

    testWidgets('settlement tab is not rendered', (tester) async {
      await tester.pumpWidget(buildSubject(hasSettlementAccess: false));
      await tester.pumpAndSettle();

      expect(find.text('정산'), findsNothing);
    });

    testWidgets('remaining 4 tabs are rendered', (tester) async {
      await tester.pumpWidget(buildSubject(hasSettlementAccess: false));
      await tester.pumpAndSettle();

      expect(find.text('홈'), findsOneWidget);
      expect(find.text('신청관리'), findsOneWidget);
      expect(find.text('체크인'), findsOneWidget);
      expect(find.text('더보기'), findsOneWidget);
    });

    testWidgets(
        'selectedIndex 4 (더보기 branch) maps to display index 3 when '
        'settlement is hidden', (tester) async {
      await tester.pumpWidget(
        buildSubject(currentIndex: 4, hasSettlementAccess: false),
      );
      await tester.pumpAndSettle();

      // Branch 4 (더보기) → display index 3 (settlement 탭이 없으므로 한 칸 당겨짐)
      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 3);
    });

    testWidgets(
        'selectedIndex falls back to 0 when on settlement branch without '
        'access', (tester) async {
      // branch 3 = settlement, but hasSettlementAccess is false
      await tester.pumpWidget(
        buildSubject(currentIndex: 3, hasSettlementAccess: false),
      );
      await tester.pumpAndSettle();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 0);
    });
  });
}
