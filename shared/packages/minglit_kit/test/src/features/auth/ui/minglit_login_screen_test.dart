import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/features/auth/ui/minglit_login_screen.dart';

Widget _buildLoginScreen({VoidCallback? onDevTrigger}) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: MinglitLoginScreen(onDevTrigger: onDevTrigger),
      ),
    ),
  );
}

void main() {
  group('MinglitLoginScreen — _DevTriggerLogo 5-탭 #2340 regression guard', () {
    testWidgets('onDevTrigger null → devTriggerKey 없음 (일반 로고 렌더링)', (
      tester,
    ) async {
      await tester.pumpWidget(_buildLoginScreen());
      await tester.pump();

      expect(
        find.byKey(MinglitLoginScreen.devTriggerKey),
        findsNothing,
        reason: 'onDevTrigger null이면 GestureDetector 렌더링하지 않아야 함',
      );
    });

    testWidgets(
      'onDevTrigger 비-null → devTriggerKey 존재 (GestureDetector 렌더링)',
      (
        tester,
      ) async {
        await tester.pumpWidget(_buildLoginScreen(onDevTrigger: () {}));
        await tester.pump();

        expect(
          find.byKey(MinglitLoginScreen.devTriggerKey),
          findsOneWidget,
          reason: 'onDevTrigger가 있으면 GestureDetector가 렌더링되어야 함',
        );
      },
    );

    testWidgets('5회 연속 탭 → onTrigger 호출', (tester) async {
      var triggered = 0;
      await tester.pumpWidget(
        _buildLoginScreen(onDevTrigger: () => triggered++),
      );
      await tester.pump();

      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byKey(MinglitLoginScreen.devTriggerKey));
        await tester.pump();
      }

      expect(triggered, 1, reason: '5회 탭 후 정확히 1번 트리거되어야 함');
    });

    testWidgets('4회 탭 → onTrigger 호출 안 됨', (tester) async {
      var triggered = 0;
      await tester.pumpWidget(
        _buildLoginScreen(onDevTrigger: () => triggered++),
      );
      await tester.pump();

      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byKey(MinglitLoginScreen.devTriggerKey));
        await tester.pump();
      }

      expect(triggered, 0, reason: '4회만 탭하면 트리거되지 않아야 함');
    });

    testWidgets('5회 탭 후 추가 5회 탭 → 2번 트리거', (tester) async {
      var triggered = 0;
      await tester.pumpWidget(
        _buildLoginScreen(onDevTrigger: () => triggered++),
      );
      await tester.pump();

      for (var i = 0; i < 10; i++) {
        await tester.tap(find.byKey(MinglitLoginScreen.devTriggerKey));
        await tester.pump();
      }

      expect(triggered, 2, reason: '10회 탭은 2번 트리거되어야 함 (5+5)');
    });

    testWidgets('픽스 revert guard — 카운트 5 미만 시 onTrigger 호출 안 됨', (
      tester,
    ) async {
      var triggered = 0;
      await tester.pumpWidget(
        _buildLoginScreen(onDevTrigger: () => triggered++),
      );
      await tester.pump();

      for (var count = 1; count < 5; count++) {
        // n회 탭 후 트리거 안 됨 확인
        for (var i = 0; i < count; i++) {
          await tester.tap(find.byKey(MinglitLoginScreen.devTriggerKey));
          await tester.pump();
        }
        expect(triggered, 0, reason: '$count회 탭은 트리거되면 안 됨');

        // 재시작을 위해 5회 연속 탭으로 카운트 리셋
        for (var i = 0; i < 5 - count; i++) {
          await tester.tap(find.byKey(MinglitLoginScreen.devTriggerKey));
          await tester.pump();
        }
        triggered = 0; // 리셋 후 초기화
      }
    });
  });
}
