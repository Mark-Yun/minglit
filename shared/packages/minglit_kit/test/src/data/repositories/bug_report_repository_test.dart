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
    });
  });
}
