import 'dart:io';

import 'package:app_partner/src/features/onboarding/widgets/address_search_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  setUp(() {
    Log.clear();
  });

  tearDown(() {
    HttpOverrides.global = null;
  });

  group('AddressSearchDialog error logging', () {
    testWidgets('API 예외 시 Log.e 호출 + 에러 메시지 표시', (tester) async {
      // Override HTTP to throw on any request
      HttpOverrides.global = _ThrowingHttpOverrides();

      await tester.pumpWidget(
        const MaterialApp(home: AddressSearchDialog()),
      );

      // Enter search text (minimum 2 chars)
      await tester.enterText(find.byType(TextField), '서울시 강남구');
      await tester.pump();

      // Tap search button
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Verify error message is shown to user
      expect(find.text('네트워크 연결을 확인해주세요'), findsOneWidget);

      // Verify error was logged
      final logs = Log.export();
      expect(
        logs,
        contains('[AddressSearchDialog] Address search Error'),
        reason: 'Log.e should be called when HTTP request fails',
      );
    });

    testWidgets('API 예외 시 결과 목록 비움 + 로딩 해제', (tester) async {
      HttpOverrides.global = _ThrowingHttpOverrides();

      await tester.pumpWidget(
        const MaterialApp(home: AddressSearchDialog()),
      );

      await tester.enterText(find.byType(TextField), '테스트 주소');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // No loading indicator after error
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // No list items
      expect(find.byType(ListTile), findsNothing);
    });
  });
}

/// HttpOverrides that throws on any HTTP request to simulate network errors.
class _ThrowingHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw const SocketException('Simulated network error');
  }
}
