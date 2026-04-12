import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/services/bug_report_collector.dart';
import 'package:minglit_kit/src/utils/qa_bug_report_channel.dart';
import 'package:mocktail/mocktail.dart';

class MockBugReportCollector extends Mock implements BugReportCollector {
  MockBugReportCollector() : super();

  @override
  GlobalKey get boundaryKey => GlobalKey();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QaBugReportChannel', () {
    late MockBugReportCollector mockCollector;

    setUp(() {
      mockCollector = MockBugReportCollector();
      when(
        () => mockCollector.submitReport(
          title: any(named: 'title'),
          description: any(named: 'description'),
          scenarioId: any(named: 'scenarioId'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer((_) async {});
    });

    tearDown(() {
      // Reset the channel handler after each test
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.minglit.dev/qa_bug_report'),
        null,
      );
    });

    test(
      'triggerBugReport call invokes BugReportCollector.submitReport',
      () async {
        QaBugReportChannel.initialize(mockCollector);

        // Simulate what the Android BroadcastReceiver sends to Flutter
        const channel = MethodChannel('com.minglit.dev/qa_bug_report');
        await TestDefaultBinaryMessengerBinding
            .instance
            .defaultBinaryMessenger
            .handlePlatformMessage(
          channel.name,
          channel.codec.encodeMethodCall(
            const MethodCall(
              'triggerBugReport',
              {
                'title': 'U-S04 이벤트 상세 — CTA 버튼 잘림',
                'description': '이벤트 상세 하단 신청하기 버튼이 SafeArea 밖으로 나감',
                'scenario_id': 'U-S04',
                'session_id': '20260412-173833',
              },
            ),
          ),
          (_) {},
        );

        verify(
          () => mockCollector.submitReport(
            title: 'U-S04 이벤트 상세 — CTA 버튼 잘림',
            description: '이벤트 상세 하단 신청하기 버튼이 SafeArea 밖으로 나감',
            scenarioId: 'U-S04',
            sessionId: '20260412-173833',
          ),
        ).called(1);
      },
    );

    test('unknown method call is ignored without error', () async {
      QaBugReportChannel.initialize(mockCollector);

      const channel = MethodChannel('com.minglit.dev/qa_bug_report');
      await TestDefaultBinaryMessengerBinding
          .instance
          .defaultBinaryMessenger
          .handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(
          const MethodCall('unknownMethod', {}),
        ),
        (_) {},
      );

      verifyNever(
        () => mockCollector.submitReport(
          title: any(named: 'title'),
          description: any(named: 'description'),
          scenarioId: any(named: 'scenarioId'),
          sessionId: any(named: 'sessionId'),
        ),
      );
    });

    test('missing optional fields use defaults', () async {
      QaBugReportChannel.initialize(mockCollector);

      const channel = MethodChannel('com.minglit.dev/qa_bug_report');
      await TestDefaultBinaryMessengerBinding
          .instance
          .defaultBinaryMessenger
          .handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(
          const MethodCall('triggerBugReport', <String, dynamic>{}),
        ),
        (_) {},
      );

      verify(
        () => mockCollector.submitReport(
          title: 'QA Bug Report',
          description: '',
          scenarioId: null,
          sessionId: null,
        ),
      ).called(1);
    });
  });
}
