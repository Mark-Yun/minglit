import 'package:app_partner/src/features/party/event/detail/event_application_controller.dart';
import 'package:app_partner/src/features/party/event/widgets/event_application_review_dialog.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class EventApplicationListView extends ConsumerWidget {
  const EventApplicationListView({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(eventApplicationsProvider(eventId));
    final theme = Theme.of(context);

    // Listen for review success
    ref.listen(eventApplicationReviewControllerProvider, (_, next) {
      if (next is AsyncData) {
        ref.invalidate(eventApplicationsProvider(eventId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('심사 처리가 완료되었습니다.')),
        );
      }
      if (next is AsyncError) {
        handleMinglitError(context, next.error, next.stackTrace);
      }
    });

    return MinglitAsyncValueWidget(
      value: applicationsAsync,
      data: (applications) {
        if (applications.isEmpty) {
          return const Center(
            child: Text('신청 내역이 없습니다.'),
          );
        }

        final pendingReviews = applications
            .where((app) => app.status == 'pending_review')
            .toList();
        final others = applications
            .where((app) => app.status != 'pending_review')
            .toList();

        return ListView(
          padding: const EdgeInsets.all(MinglitSpacing.medium),
          children: [
            if (pendingReviews.isNotEmpty) ...[
              Text(
                '심사 대기 중 (${pendingReviews.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: MinglitSpacing.small),
              ...pendingReviews.map((app) => _ApplicationCard(app: app)),
              const SizedBox(height: MinglitSpacing.large),
            ],
            if (others.isNotEmpty) ...[
              Text(
                '처리 완료 (${others.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: MinglitSpacing.small),
              ...others.map((app) => _ApplicationCard(app: app)),
            ],
          ],
        );
      },
    );
  }
}

class _ApplicationCard extends ConsumerWidget {
  const _ApplicationCard({required this.app});

  final EventApplication app;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = app.user;

    return Card(
      margin: const EdgeInsets.only(bottom: MinglitSpacing.small),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            user?.name.characters.first ?? '?',
            style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
          ),
        ),
        title: Text(user?.name ?? '익명 유저'),
        subtitle: Text(
          '${user?.gender == 'male' ? "남" : "여"} · ${user?.birthDate ?? ""}',
        ),
        trailing: _StatusBadge(status: app.status),
        onTap: app.status == 'pending_review'
            ? () async {
                final result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) =>
                      EventApplicationReviewDialog(application: app),
                );

                if (result != null) {
                  await ref
                      .read(eventApplicationReviewControllerProvider.notifier)
                      .reviewApplication(
                        applicationId: app.id,
                        status: result['status'] as String,
                        reason: result['reason'] as String?,
                      );
                }
              }
            : null,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color color;
    String label;

    switch (status) {
      case 'pending_review':
        color = Colors.orange;
        label = '심사 중';
      case 'approved':
        color = Colors.green;
        label = '승인됨';
      case 'rejected':
        color = theme.colorScheme.error;
        label = '거절됨';
      case 'paid':
        color = theme.colorScheme.primary;
        label = '결제완료';
      default:
        color = theme.colorScheme.outline;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.small,
        vertical: MinglitSpacing.xxsmall,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MinglitRadius.small),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
