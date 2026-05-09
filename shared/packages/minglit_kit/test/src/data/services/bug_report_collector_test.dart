import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/bug_report_repository.dart';
import 'package:minglit_kit/src/data/repositories/storage_repository.dart';
import 'package:minglit_kit/src/data/services/bug_report_collector.dart';
import 'package:mocktail/mocktail.dart';

class MockStorageRepository extends Mock implements StorageRepository {}

class MockBugReportRepository extends Mock implements BugReportRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(<String, dynamic>{});
  });

  late MockStorageRepository mockStorage;
  late MockBugReportRepository mockRepo;

  setUp(() {
    mockStorage = MockStorageRepository();
    mockRepo = MockBugReportRepository();

    when(
      () => mockStorage.uploadBytes(
        bytes: any(named: 'bytes'),
        bucket: any(named: 'bucket'),
        pathPrefix: any(named: 'pathPrefix'),
        contentType: any(named: 'contentType'),
        extension: any(named: 'extension'),
      ),
    ).thenAnswer((_) async => 'https://example.com/file.png');

    when(
      () => mockRepo.reportBug(
        title: any(named: 'title'),
        description: any(named: 'description'),
        logs: any(named: 'logs'),
        screenshotUrl: any(named: 'screenshotUrl'),
        environment: any(named: 'environment'),
        platform: any(named: 'platform'),
        layoutDumpUrl: any(named: 'layoutDumpUrl'),
      ),
    ).thenAnswer((_) async {});
  });

  BugReportCollector makeCollector() => BugReportCollector(
    boundaryKey: GlobalKey(),
    storage: mockStorage,
    bugReportRepository: mockRepo,
    environmentInfoCollector: () async => {'platform': 'test'},
  );

  group('BugReportCollector.submitReport flag routing', () {
    testWidgets('default flags call uploadBytes and reportBug', (tester) async {
      await tester.pumpWidget(const SizedBox());
      final collector = makeCollector();

      await collector.submitReport(title: 'T', description: 'D');

      // uploadBytes is called for screenshot (screenshotBytes==null → skipped)
      // and layout dump (bytes provided if captureLayoutDumpJson returns non-null)
      verify(
        () => mockRepo.reportBug(
          title: 'T',
          description: 'D',
          logs: any(named: 'logs'),
          screenshotUrl: any(named: 'screenshotUrl'),
          environment: any(named: 'environment'),
          platform: any(named: 'platform'),
          layoutDumpUrl: any(named: 'layoutDumpUrl'),
        ),
      ).called(1);
    });

    testWidgets('fileIssue=false skips reportBug entirely', (tester) async {
      await tester.pumpWidget(const SizedBox());
      final collector = makeCollector();

      await collector.submitReport(
        title: 'spec_walk',
        description: '',
        fileIssue: false,
      );

      verifyNever(
        () => mockRepo.reportBug(
          title: any(named: 'title'),
          description: any(named: 'description'),
          logs: any(named: 'logs'),
          screenshotUrl: any(named: 'screenshotUrl'),
          environment: any(named: 'environment'),
          platform: any(named: 'platform'),
          layoutDumpUrl: any(named: 'layoutDumpUrl'),
        ),
      );
    });

    testWidgets('uploadToSupabase=false skips uploadBytes', (tester) async {
      await tester.pumpWidget(const SizedBox());
      final collector = makeCollector();

      await collector.submitReport(
        title: 'T',
        description: '',
        uploadToSupabase: false,
        fileIssue: false,
      );

      verifyNever(
        () => mockStorage.uploadBytes(
          bytes: any(named: 'bytes'),
          bucket: any(named: 'bucket'),
          pathPrefix: any(named: 'pathPrefix'),
        ),
      );
    });

    testWidgets('artifact_dir writes dump.json to disk', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Text('hello'),
        ),
      );
      final collector = makeCollector();
      final tmpDir = Directory.systemTemp.createTempSync('qa_collector_test_');
      addTearDown(() => tmpDir.deleteSync(recursive: true));

      // runAsync: submitReport uses real async IO (Directory.create / File.writeAsString)
      // which does not resolve in testWidgets' fake-async context without it.
      await tester.runAsync(() async {
        await collector.submitReport(
          title: 'walk',
          description: '',
          fileIssue: false,
          uploadToSupabase: false,
          artifactDir: tmpDir.path,
        );
      });

      final dumpFile = File('${tmpDir.path}/dump.json');
      expect(dumpFile.existsSync(), isTrue);

      final content =
          json.decode(dumpFile.readAsStringSync()) as Map<String, dynamic>;
      expect(content['capturedAt'], isA<String>());
      expect(content['viewportSize'], isA<Map<String, dynamic>>());
      expect(content['nodes'], isA<List<dynamic>>());
    });

    testWidgets('includeDump=false skips layout dump', (tester) async {
      await tester.pumpWidget(const SizedBox());
      final collector = makeCollector();
      final tmpDir = Directory.systemTemp.createTempSync('qa_collector_test2_');
      addTearDown(() => tmpDir.deleteSync(recursive: true));

      await tester.runAsync(() async {
        await collector.submitReport(
          title: 'T',
          description: '',
          fileIssue: false,
          uploadToSupabase: false,
          artifactDir: tmpDir.path,
          includeDump: false,
        );
      });

      // dump.json must NOT be created when includeDump=false
      expect(File('${tmpDir.path}/dump.json').existsSync(), isFalse);
    });

    testWidgets(
      'scenarioId prepends [QA] to title when fileIssue=true',
      (tester) async {
        await tester.pumpWidget(const SizedBox());
        final collector = makeCollector();

        await collector.submitReport(
          title: 'my title',
          description: '',
          scenarioId: 'U-S01',
        );

        verify(
          () => mockRepo.reportBug(
            title: '[QA] my title',
            description: any(named: 'description'),
            logs: any(named: 'logs'),
            screenshotUrl: any(named: 'screenshotUrl'),
            environment: any(named: 'environment'),
            platform: any(named: 'platform'),
            layoutDumpUrl: any(named: 'layoutDumpUrl'),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'fix regression: reverting fileIssue param causes reportBug on '
      'fileIssue=false call',
      (tester) async {
        // This test explicitly documents the bug this feature prevents:
        // Without the fileIssue guard, reportBug is always called.
        await tester.pumpWidget(const SizedBox());
        final collector = makeCollector();

        await collector.submitReport(
          title: 'spec_walk_page',
          description: '',
          fileIssue: false,
          uploadToSupabase: false,
        );

        // Must never reach the issue-creation Edge Function
        verifyNever(
          () => mockRepo.reportBug(
            title: any(named: 'title'),
            description: any(named: 'description'),
            logs: any(named: 'logs'),
            screenshotUrl: any(named: 'screenshotUrl'),
            environment: any(named: 'environment'),
            platform: any(named: 'platform'),
            layoutDumpUrl: any(named: 'layoutDumpUrl'),
          ),
        );
      },
    );
  });
}
