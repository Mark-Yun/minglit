import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/src/features/notification/notification_list_controller.dart';

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

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
              ref.read(notificationListProvider.notifier).markAllAsRead();
            },
          ),
        ],
      ),
      body: notificationState.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(child: Text('알림이 없습니다.'));
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(notificationListProvider.notifier).refresh(),
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
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
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    ref.read(notificationListProvider.notifier)
                        .deleteNotification(id);
                  },
                  child: ListTile(
                    tileColor: isRead ? null : theme.colorScheme.primary.withOpacity(0.05),
                    title: Text(
                      title,
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(body),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MM/dd HH:mm').format(createdAt),
                          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
                        ),
                      ],
                    ),
                    onTap: () {
                      ref.read(notificationListProvider.notifier)
                          .markAsRead(id);
                      
                      if (deepLink != null && deepLink.isNotEmpty) {
                        // TODO: Use Coordinator or Router to navigate
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('이동: $deepLink')),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('에러: $err')),
      ),
    );
  }
}
