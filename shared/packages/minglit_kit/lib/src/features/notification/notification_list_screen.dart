import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/src/features/notification/notification_list_controller.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_async_value_widget.dart';

/// Displays the list of user notifications.
class NotificationListScreen extends ConsumerWidget {
  /// Creates a notification list screen.
  const NotificationListScreen({super.key});

  /// Builds the notification list UI.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 센터'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: '모두 읽음',
            onPressed: () {
              unawaited(
                ref.read(notificationListProvider.notifier).markAllAsRead(),
              );
            },
          ),
        ],
      ),
      body: MinglitAsyncValueWidget(
        value: notificationState,
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(child: Text('알림이 없습니다.'));
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(notificationListProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final id = notification['id'] as String;
                final isRead = notification['is_read'] as bool? ?? false;
                final title = notification['title'] as String? ?? '';
                final body = notification['body'] as String? ?? '';
                final createdAtStr = notification['created_at'] as String;
                final createdAt = DateTime.parse(createdAtStr).toLocal();
                final deepLink = notification['deep_link'] as String?;

                return Dismissible(
                  key: Key(id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: MinglitColors.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: MinglitSpacing.large),
                    child: const Icon(
                      Icons.delete,
                      color: MinglitColors.background,
                    ),
                  ),
                  onDismissed: (_) {
                    unawaited(
                      ref
                          .read(notificationListProvider.notifier)
                          .deleteNotification(id),
                    );
                  },
                  child: ListTile(
                    tileColor: isRead
                        ? null
                        : theme.colorScheme.primary.withValues(
                            alpha: MinglitOpacity.tintFill,
                          ),
                    title: Text(
                      title,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontWeight: isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: MinglitSpacing.xsmall),
                        Text(body),
                        const SizedBox(height: MinglitSpacing.xsmall),
                        Text(
                          DateFormat('MM/dd HH:mm').format(createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      unawaited(
                        ref
                            .read(notificationListProvider.notifier)
                            .markAsRead(id),
                      );

                      final trimmed = deepLink?.trim();
                      if (trimmed == null || trimmed.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('이동할 링크가 없습니다.')),
                        );
                        return;
                      }

                      if (!trimmed.startsWith('/')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('올바르지 않은 링크입니다.')),
                        );
                        return;
                      }

                      unawaited(context.push(trimmed));
                    },
                  ),
                );
              },
            ),
          );
        },
        error: (err, stack) => Center(child: Text('에러: $err')),
      ),
    );
  }
}
