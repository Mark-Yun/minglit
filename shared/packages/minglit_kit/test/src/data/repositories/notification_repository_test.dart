import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/notification_repository.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

void main() {
  late MockSupabaseClient mockClient;
  late NotificationRepository repository;

  final now = DateTime.now();

  setUp(() {
    mockClient = createMockSupabase();
    repository = NotificationRepository(mockClient);
  });

  group('NotificationRepository', () {
    group('upsertToken', () {
      test('completes without error', () async {
        mockTable(mockClient, 'fcm_tokens');

        await expectLater(
          repository.upsertToken(
            userId: 'user_1',
            token: 'fcm_token_abc',
            deviceType: 'android',
          ),
          completes,
        );
      });
    });

    group('deleteToken', () {
      test('completes without error', () async {
        mockTable(mockClient, 'fcm_tokens');

        await expectLater(
          repository.deleteToken('fcm_token_abc'),
          completes,
        );
      });
    });

    group('getNotifications', () {
      test('returns list of notifications', () async {
        final notificationJson = {
          'id': 'notif_1',
          'user_id': 'user_1',
          'title': '새로운 이벤트',
          'body': '강남 밍글릿 이벤트가 등록되었습니다.',
          'is_read': false,
          'created_at': now.toIso8601String(),
        };

        mockTable(
          mockClient,
          'user_notifications',
          selectData: [notificationJson],
        );

        final result = await repository.getNotifications();

        expect(result, hasLength(1));
        expect(result.first['title'], '새로운 이벤트');
        expect(result.first['is_read'], false);
      });

      test('supports pagination', () async {
        mockTable(mockClient, 'user_notifications', selectData: []);

        final result = await repository.getNotifications(limit: 10, offset: 20);
        expect(result, isEmpty);
      });
    });

    group('markAsRead', () {
      test('completes without error', () async {
        mockTable(mockClient, 'user_notifications');

        await expectLater(
          repository.markAsRead('notif_1'),
          completes,
        );
      });
    });

    group('markAllAsRead', () {
      test('completes without error', () async {
        mockTable(mockClient, 'user_notifications');

        await expectLater(
          repository.markAllAsRead('user_1'),
          completes,
        );
      });
    });

    group('deleteNotification', () {
      test('completes without error', () async {
        mockTable(mockClient, 'user_notifications');

        await expectLater(
          repository.deleteNotification('notif_1'),
          completes,
        );
      });
    });

    group('getSettings', () {
      test('returns settings when found', () async {
        final settingsJson = {
          'user_id': 'user_1',
          'push_enabled': true,
          'email_enabled': false,
          'marketing_enabled': false,
          'updated_at': now.toIso8601String(),
        };

        mockTable(
          mockClient,
          'user_settings',
          maybeSingleData: settingsJson,
        );

        final result = await repository.getSettings('user_1');

        expect(result, isNotNull);
      });

      test('returns null when not found', () async {
        mockTable(
          mockClient,
          'user_settings',
          maybeSingleData: null,
        );

        final result = await repository.getSettings('user_unknown');
        expect(result, isNull);
      });
    });

    group('updateSettings', () {
      test('completes without error', () async {
        mockTable(mockClient, 'user_settings');

        await expectLater(
          repository.updateSettings(
            'user_1',
            {'push_enabled': false},
          ),
          completes,
        );
      });
    });
  });
}
