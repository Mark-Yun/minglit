import 'package:app_partner/src/features/admin/ops_cicd_status/ops_cicd_status_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OpsCicdStatusSnapshot parses branch workflows and issues', () {
    final snapshot = OpsCicdStatusSnapshot.fromJson({
      'generated_at': '2026-05-24T01:00:00Z',
      'repository': 'Mark-Yun/minglit',
      'branches': [
        {
          'key': 'dev',
          'branch_name': 'dev',
          'head_sha': 'abcdef123456',
          'state': 'success',
          'workflows': [
            {
              'key': 'dev-deploy',
              'file': 'dev-deploy.yml',
              'lane': 'deploy',
              'label': 'dev Deploy',
              'state': 'running',
              'status': 'in_progress',
              'conclusion': null,
              'run_id': 12,
              'run_url': 'https://github.com/Mark-Yun/minglit/actions/runs/12',
              'updated_at': '2026-05-24T00:59:00Z',
            },
          ],
          'commit_statuses': [
            {
              'context': 'dev-soak/backend-simulator',
              'state': 'success',
              'description': '24h soak passed',
              'target_url': null,
              'updated_at': '2026-05-24T00:58:00Z',
            },
          ],
        },
      ],
      'issues': [
        {
          'number': 42,
          'title': '[P1-high] dev-deploy failed',
          'state': 'open',
          'url': 'https://github.com/Mark-Yun/minglit/issues/42',
          'labels': ['ci-failure', 'P1-high'],
          'updated_at': '2026-05-24T00:57:00Z',
        },
      ],
    });

    expect(snapshot.repository, 'Mark-Yun/minglit');
    expect(snapshot.branches.single.state, OpsCicdState.success);
    expect(
      snapshot.branches.single.workflows.single.state,
      OpsCicdState.running,
    );
    expect(
      snapshot.branches.single.commitStatuses.single.context,
      'dev-soak/backend-simulator',
    );
    expect(snapshot.issues.single.number, 42);
  });
}
