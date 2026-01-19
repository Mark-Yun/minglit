import 'dart:async';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/data/repositories/notification_repository.dart';
import 'package:minglit_kit/src/features/notification/notification_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_list_controller.g.dart';

@riverpod
class NotificationList extends _$NotificationList {
  late final NotificationRepository _repository;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    _repository = ref.watch(notificationRepositoryProvider);
    return _fetchNotifications();
  }

  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    return _repository.getNotifications();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchNotifications);
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    // Optimistic Update
    state = state.whenData((notifications) {
      return notifications.map((n) {
        if (n['id'] == id) {
          return Map<String, dynamic>.from(n)..['is_read'] = true;
        }
        return n;
      }).toList();
    });
  }

  Future<void> markAllAsRead() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await _repository.markAllAsRead(user.id);
    unawaited(refresh());
  }

  Future<void> deleteNotification(String id) async {
    await _repository.deleteNotification(id);
    // Optimistic Update
    state = state.whenData((notifications) {
      return notifications.where((n) => n['id'] != id).toList();
    });
  }
}




