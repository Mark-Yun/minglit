import 'package:minglit_kit/src/data/models/user_settings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
  NotificationRepository(this._client);
  final SupabaseClient _client;

  /// FCM 토큰을 서버에 등록하거나 갱신합니다.
  Future<void> upsertToken({
    required String userId,
    required String token,
    required String deviceType,
  }) async {
    await _client.from('fcm_tokens').upsert(
      {
        'user_id': userId,
        'token': token,
        'device_type': deviceType,
        'last_updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'token', // 토큰이 중복되면 업데이트
    );
  }

  /// 로그아웃 시 토큰 삭제 (선택 사항)
  Future<void> deleteToken(String token) async {
    await _client.from('fcm_tokens').delete().eq('token', token);
  }

  /// 알림 목록 조회 (페이지네이션)
  Future<List<Map<String, dynamic>>> getNotifications({
    int limit = 20,
    int offset = 0,
  }) async {
    return await _client
        .from('user_notifications')
        .select()
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
  }

  /// 알림 읽음 처리
  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('user_notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  /// 모든 알림 읽음 처리
  Future<void> markAllAsRead(String userId) async {
    await _client
        .from('user_notifications')
        .update({'is_read': true})
        .eq('user_id', userId);
  }

  /// 알림 삭제
  Future<void> deleteNotification(String notificationId) async {
    await _client.from('user_notifications').delete().eq('id', notificationId);
  }

  /// 유저 알림 설정 조회
  Future<UserSettings?> getSettings(String userId) async {
    final response = await _client
        .from('user_settings')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    
    if (response == null) return null;
    return UserSettings.fromJson(response);
  }

  /// 유저 알림 설정 업데이트
  Future<void> updateSettings(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    await _client.from('user_settings').upsert({
      'user_id': userId,
      ...updates,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}