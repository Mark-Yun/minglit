import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/e2e_auth.dart';
import '../utils/e2e_helpers.dart';

/// CUJ 11: 알림 생성/조회/읽음처리
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient adminClient;
  late String testEmail;
  late String testUserId;
  late String notificationId;

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();
    testEmail = await getTestUserEmail(adminClient, gender: 'male');
    await signInAsTestUser(testEmail);
    testUserId = Supabase.instance.client.auth.currentUser!.id;

    // admin client로 테스트 알림 insert
    final res = await adminClient
        .from('user_notifications')
        .insert({
          'user_id': testUserId,
          'title': '[테스트] 알림 제목',
          'body': '[테스트] 알림 본문입니다.',
          'category': 'service',
          'deep_link': 'minglit://test/notification',
          'is_read': false,
          'metadata': {'test': true},
        })
        .select('id')
        .single();

    notificationId = res['id'] as String;
  });

  tearDownAll(() async {
    // admin client로 테스트 데이터 정리
    await adminClient
        .from('user_notifications')
        .delete()
        .eq('user_id', testUserId);

    await signOut();
  });

  group('CUJ 11: 알림', () {
    testWidgets('알림 목록을 조회할 수 있다', (tester) async {
      final client = Supabase.instance.client;

      final notifications = await client
          .from('user_notifications')
          .select()
          .eq('user_id', testUserId) as List;

      expect(notifications, isNotEmpty, reason: 'setUpAll에서 삽입한 알림이 있어야 한다');

      final inserted = notifications.firstWhere(
        (n) => (n as Map<String, dynamic>)['id'] == notificationId,
        orElse: () => null,
      );
      expect(inserted, isNotNull, reason: '삽입한 알림 ID가 목록에 있어야 한다');

      final notification = inserted as Map<String, dynamic>;
      expect(notification['title'], equals('[테스트] 알림 제목'));
      expect(notification['body'], equals('[테스트] 알림 본문입니다.'));
      expect(notification['category'], equals('service'));
      expect(notification['is_read'], isFalse);
    });

    testWidgets('알림을 읽음 처리할 수 있다', (tester) async {
      final client = Supabase.instance.client;

      await client
          .from('user_notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', testUserId);

      final updated = await client
          .from('user_notifications')
          .select('id, is_read')
          .eq('id', notificationId)
          .single();

      expect(updated['is_read'], isTrue, reason: '읽음 처리 후 is_read가 true여야 한다');
    });

    testWidgets('알림을 삭제할 수 있다', (tester) async {
      final client = Supabase.instance.client;

      await client
          .from('user_notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', testUserId);

      final result = await client
          .from('user_notifications')
          .select('id')
          .eq('id', notificationId)
          .maybeSingle();

      expect(result, isNull, reason: '삭제 후 해당 알림이 조회되지 않아야 한다');
    });
  });
}
