import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/bug_report_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

void main() {
  late MockSupabaseClient mockClient;
  late BugReportRepository repository;

  late MockFunctionsClient mockFunctions;

  setUp(() {
    mockClient = createMockSupabase();
    mockFunctions = mockClient.functions as MockFunctionsClient;
    repository = BugReportRepository(mockClient);
  });

  group('BugReportRepository', () {
    group('reportBug', () {
      test('sends bug report via edge function', () async {
        when(
          () => mockFunctions.invoke(
            'report-bug',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(status: 200, data: {'ok': true}),
        );

        await expectLater(
          repository.reportBug(
            title: '버그 제목',
            description: '버그 설명',
            logs: 'error log here',
          ),
          completes,
        );

        verify(
          () => mockFunctions.invoke(
            'report-bug',
            body: any(named: 'body'),
          ),
        ).called(1);
      });

      test('throws when edge function fails', () async {
        when(
          () => mockFunctions.invoke(
            'report-bug',
            body: any(named: 'body'),
          ),
        ).thenThrow(Exception('Network error'));

        expect(
          () => repository.reportBug(
            title: '버그 제목',
            description: '버그 설명',
            logs: 'error log here',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('includes optional parameters when provided', () async {
        when(
          () => mockFunctions.invoke(
            'report-bug',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(status: 200, data: {'ok': true}),
        );

        await expectLater(
          repository.reportBug(
            title: '버그 제목',
            description: '버그 설명',
            logs: 'error log here',
            screenshotUrl: 'https://example.com/screenshot.png',
            environment: {'os': 'iOS', 'version': '17.0'},
            platform: 'iOS',
          ),
          completes,
        );

        final captured = verify(
          () => mockFunctions.invoke(
            'report-bug',
            body: captureAny(named: 'body'),
          ),
        ).captured;

        final body = captured.first as Map<String, dynamic>;
        expect(body['screenshotUrl'], equals('https://example.com/screenshot.png'));
        expect(body['environment'], equals({'os': 'iOS', 'version': '17.0'}));
        expect(body['platform'], equals('iOS'));
      });

      test('excludes optional parameters when not provided', () async {
        when(
          () => mockFunctions.invoke(
            'report-bug',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(status: 200, data: {'ok': true}),
        );

        await expectLater(
          repository.reportBug(
            title: '버그 제목',
            description: '버그 설명',
            logs: 'error log here',
          ),
          completes,
        );

        final captured = verify(
          () => mockFunctions.invoke(
            'report-bug',
            body: captureAny(named: 'body'),
          ),
        ).captured;

        final body = captured.first as Map<String, dynamic>;
        expect(body.containsKey('screenshotUrl'), isFalse);
        expect(body.containsKey('environment'), isFalse);
        expect(body.containsKey('platform'), isFalse);
      });
    });
  });
}
