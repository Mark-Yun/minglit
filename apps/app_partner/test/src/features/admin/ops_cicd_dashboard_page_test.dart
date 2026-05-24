import 'package:app_partner/src/features/admin/ops_cicd_status/ops_cicd_dashboard_page.dart';
import 'package:app_partner/src/features/admin/ops_cicd_status/ops_cicd_status_models.dart';
import 'package:app_partner/src/features/admin/ops_cicd_status/ops_cicd_status_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/minglit_kit.dart';

void main() {
  testWidgets('OpsCicdDashboardPage renders branch graph and filed issues', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          opsCicdStatusSnapshotProvider.overrideWith((ref) async {
            return _sampleSnapshot;
          }),
        ],
        child: const MaterialApp(home: OpsCicdDashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CI/CD 상태'), findsOneWidget);
    expect(find.text('Release Flow'), findsOneWidget);
    expect(find.text('dev'), findsOneWidget);
    expect(find.text('dev Deploy'), findsOneWidget);
    expect(find.text('Filed Issues'), findsOneWidget);
    expect(find.textContaining('#42', skipOffstage: false), findsOneWidget);
  });
}

final OpsCicdStatusSnapshot _sampleSnapshot = OpsCicdStatusSnapshot(
  generatedAt: DateTime.parse('2026-05-24T01:00:00Z'),
  repository: 'Mark-Yun/minglit',
  branches: [
    OpsCicdBranch(
      key: 'dev',
      branchName: 'dev',
      headSha: 'abcdef123456',
      state: OpsCicdState.success,
      workflows: [
        OpsCicdWorkflow(
          key: 'dev-deploy',
          file: 'dev-deploy.yml',
          lane: 'deploy',
          label: 'dev Deploy',
          state: OpsCicdState.success,
          status: 'completed',
          conclusion: 'success',
          runId: 12,
          runUrl: null,
          updatedAt: DateTime.parse('2026-05-24T00:59:00Z'),
        ),
      ],
      commitStatuses: const [],
    ),
  ],
  issues: [
    OpsCicdIssue(
      number: 42,
      title: '[P1-high] dev-deploy failed',
      state: 'open',
      url: 'https://github.com/Mark-Yun/minglit/issues/42',
      labels: const ['ci-failure', 'P1-high'],
      updatedAt: DateTime.parse('2026-05-24T00:57:00Z'),
    ),
  ],
);
