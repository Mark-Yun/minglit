import 'dart:async';

import 'package:app_partner/src/features/admin/ops_cicd_status/ops_cicd_status_models.dart';
import 'package:app_partner/src/features/admin/ops_cicd_status/ops_cicd_status_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:url_launcher/url_launcher.dart';

class OpsCicdDashboardPage extends ConsumerWidget {
  const OpsCicdDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(opsCicdStatusSnapshotProvider);
    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: 'CI/CD 상태'),
      body: SafeArea(
        child: snapshot.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(opsCicdStatusSnapshotProvider),
          ),
          data: (data) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(opsCicdStatusSnapshotProvider);
              await ref.read(opsCicdStatusSnapshotProvider.future);
            },
            child: _DashboardBody(snapshot: data),
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.snapshot});

  final OpsCicdStatusSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        MinglitSpacing.medium,
        MinglitSpacing.medium,
        MinglitSpacing.medium,
        MinglitSpacing.xxxlarge,
      ),
      children: [
        _HeroSummary(snapshot: snapshot),
        const SizedBox(height: MinglitSpacing.large),
        Text(
          'Release Flow',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        for (final branch in snapshot.branches) ...[
          _BranchLane(branch: branch),
          const SizedBox(height: MinglitSpacing.medium),
        ],
        const SizedBox(height: MinglitSpacing.small),
        Text(
          'Filed Issues',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        if (snapshot.issues.isEmpty)
          const _EmptyIssuesCard()
        else
          for (final issue in snapshot.issues) ...[
            _IssueTile(issue: issue),
            const SizedBox(height: MinglitSpacing.small),
          ],
      ],
    );
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({required this.snapshot});

  final OpsCicdStatusSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failed = snapshot.branches
        .where((branch) => branch.state == OpsCicdState.failure)
        .length;
    final running = snapshot.branches
        .where((branch) => branch.state == OpsCicdState.running)
        .length;
    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.large),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF102A43), Color(0xFF0B4F6C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            snapshot.repository,
            style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: MinglitSpacing.small),
          Text(
            failed == 0 ? '배포 흐름 정상 감시 중' : '$failed개 브랜치에 실패 신호',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),
          Wrap(
            spacing: MinglitSpacing.small,
            runSpacing: MinglitSpacing.small,
            children: [
              _MetricPill(
                label: 'Branches',
                value: '${snapshot.branches.length}',
              ),
              _MetricPill(label: 'Running', value: '$running'),
              _MetricPill(
                label: 'Open Issues',
                value: '${snapshot.issues.length}',
              ),
              _MetricPill(
                label: 'Updated',
                value: DateFormat(
                  'HH:mm',
                ).format(snapshot.generatedAt.toLocal()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.medium,
        vertical: MinglitSpacing.small,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$label $value',
        style: theme.textTheme.labelMedium?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _BranchLane extends StatelessWidget {
  const _BranchLane({required this.branch});

  final OpsCicdBranch branch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _stateColor(branch.state);
    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.32), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StateDot(state: branch.state),
              const SizedBox(width: MinglitSpacing.small),
              Expanded(
                child: Text(
                  branch.branchName ?? branch.key,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                branch.headSha?.substring(0, 7) ?? 'missing',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: MinglitSpacing.medium),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < branch.workflows.length; i++) ...[
                  _WorkflowNode(workflow: branch.workflows[i]),
                  if (i != branch.workflows.length - 1) _Connector(),
                ],
              ],
            ),
          ),
          if (branch.commitStatuses.isNotEmpty) ...[
            const SizedBox(height: MinglitSpacing.medium),
            Wrap(
              spacing: MinglitSpacing.small,
              runSpacing: MinglitSpacing.small,
              children: branch.commitStatuses
                  .map((status) => _CommitStatusChip(status: status))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _WorkflowNode extends StatelessWidget {
  const _WorkflowNode({required this.workflow});

  final OpsCicdWorkflow workflow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _stateColor(workflow.state);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: workflow.runUrl == null
          ? null
          : () => unawaited(launchUrl(Uri.parse(workflow.runUrl!))),
      child: Container(
        width: 156,
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StateDot(state: workflow.state),
            const SizedBox(height: MinglitSpacing.small),
            Text(
              workflow.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: MinglitSpacing.xsmall),
            Text(
              workflow.conclusion ?? workflow.status ?? 'not run',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: MinglitSpacing.xsmall),
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

class _CommitStatusChip extends StatelessWidget {
  const _CommitStatusChip({required this.status});

  final OpsCicdCommitStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.state == 'success'
        ? const Color(0xFF18864B)
        : status.state == 'pending'
        ? const Color(0xFFC97705)
        : const Color(0xFFD92D20);
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(Icons.circle, size: 8, color: color),
      label: Text('${status.context}: ${status.state}'),
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({required this.issue});

  final OpsCicdIssue issue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: const Icon(Icons.bug_report_outlined),
        title: Text(
          '#${issue.number} ${issue.title}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(issue.labels.join(' · ')),
        trailing: Icon(
          Icons.open_in_new,
          size: MinglitIconSize.small,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: () => unawaited(launchUrl(Uri.parse(issue.url))),
      ),
    );
  }
}

class _EmptyIssuesCard extends StatelessWidget {
  const _EmptyIssuesCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: const Padding(
        padding: EdgeInsets.all(MinglitSpacing.large),
        child: Text('열린 ci-failure 이슈가 없습니다.'),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 36),
            const SizedBox(height: MinglitSpacing.medium),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: MinglitSpacing.medium),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}

class _StateDot extends StatelessWidget {
  const _StateDot({required this.state});

  final OpsCicdState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _stateColor(state),
        shape: BoxShape.circle,
      ),
    );
  }
}

Color _stateColor(OpsCicdState state) {
  return switch (state) {
    OpsCicdState.success => const Color(0xFF18864B),
    OpsCicdState.warning => const Color(0xFFC97705),
    OpsCicdState.failure => const Color(0xFFD92D20),
    OpsCicdState.running => const Color(0xFF2E6FD8),
    OpsCicdState.unknown => const Color(0xFF667085),
  };
}
