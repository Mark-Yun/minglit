import 'dart:io';

import 'package:app_partner/src/features/onboarding/widgets/address_search_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements HttpClient {}

/// [HttpOverrides] that forces every [HttpClient.getUrl] to throw a
/// [SocketException], simulating a network failure.
class _FailingHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = MockHttpClient();
    when(() => client.getUrl(any())).thenThrow(
      const SocketException('Test: network unavailable'),
    );
    return client;
  }
}

void main() {
  group('AddressSearchDialog', () {
    setUpAll(() {
      registerFallbackValue(Uri.parse('https://example.com'));
    });

    setUp(() {
      Log.clear();
      HttpOverrides.global = _FailingHttpOverrides();
    });

    tearDown(() {
      HttpOverrides.global = null;
    });

    Widget buildTestWidget() {
      return const MaterialApp(
        home: AddressSearchDialog(),
      );
    }

    testWidgets('renders search field and initial guidance text', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
      expect(
        find.text('위 검색창에 주소를 입력하고 검색 버튼을 눌러주세요'),
        findsOneWidget,
      );
    });

    testWidgets('shows validation error for short keyword', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Enter a single character (minimum is 2)
      await tester.enterText(find.byType(TextField), '서');
      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      expect(find.text('두 글자 이상 입력해주세요'), findsOneWidget);
    });

    // Fix #691: API 예외 시 Log.e 호출 검증
    testWidgets('logs error via Log.e when network request fails', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Enter a valid keyword (>= 2 chars) and trigger search
      await tester.enterText(find.byType(TextField), '서울시');
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Verify error message is displayed to user
      expect(find.text('네트워크 연결을 확인해주세요'), findsOneWidget);

      // Verify Log.e was called with the expected error context
      final logOutput = Log.export();
      expect(logOutput, contains('[AddressSearchDialog]'));
      expect(logOutput, contains('Address search Error'));
    });

    testWidgets('shows network error message on exception', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.enterText(find.byType(TextField), '테스트주소');
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.text('네트워크 연결을 확인해주세요'), findsOneWidget);
      // Results should be empty
      expect(find.byType(ListTile), findsNothing);
    });
  });
}
