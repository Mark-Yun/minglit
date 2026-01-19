import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/data/repositories/notification_repository.dart';
import 'package:minglit_kit/src/features/notification/notification_service.dart';
import 'package:minglit_kit/src/logic/providers/auth_provider.dart';

final notificationListProvider = AsyncNotifierProvider.autoDispose<
    NotificationListController, List<Map<String, dynamic>>>(() {
  return NotificationListController();
});

class NotificationListController
    extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  late final NotificationRepository _repository;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    _repository = ref.watch(notificationRepositoryProvider);
    return _fetchNotifications();
  }

  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    return await _repository.getNotifications();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchNotifications());
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    // Optimistic Update
    state = state.whenData((notifications) {
      return notifications.map((n) {
        if (n['id'] == id) {
          return {...n, 'is_read': true};
        }
        return n;
      }).toList();
    });
  }

  Future<void> markAllAsRead() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    
    await _repository.markAllAsRead(user.id);
    refresh();
  }

  Future<void> deleteNotification(String id) async {
    await _repository.deleteNotification(id);
    // Optimistic Update
    state = state.whenData((notifications) {
      return notifications.where((n) => n['id'] != id).toList();
    });
  }
}
