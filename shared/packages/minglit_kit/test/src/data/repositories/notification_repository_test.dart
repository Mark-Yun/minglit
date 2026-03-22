import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/repositories/notification_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/supabase_mock_helpers.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockFunctionsClient mockFunctions;
  late NotificationRepository repository;

  final now = DateTime.now();

  setUp(() {
    mockClient = createMockSupabase();
    mockFunctions = mockClient.functions as MockFunctionsClient;
    repository = NotificationRepository(mockClient);
  });

  group('NotificationRepository', () {
    group('upsertToken', () {
      test('invokes EF with upsert_token action', () async {
        when(
          () => mockFunctions.invoke(
            'user-manage-settings',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: jsonEncode({'success': true}),
          ),
        );

        await expectLater(
          repository.upsertToken(
            userId: 'user_1',
            token: 'fcm_token_abc',
            deviceType: 'android',
          ),
          completes,
        );

        final captured = verify(
          () => mockFunctions.invoke(
            'user-manage-settings',
            body: captureAny(named: 'body'),
          ),
        ).captured;

        final body = captured.first as Map<String, dynamic>;
        expect(body['action'], 'upsert_token');
        expect(body['token'], 'fcm_token_abc');
        expect(body['device_type'], 'android');
      });

      test('throws on EF error', () async {
        when(
          () => mockFunctions.invoke(
            'user-manage-settings',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 500,
            data: jsonEncode({'error': 'Failed'}),
          ),
        );

        expect(
          () => repository.upsertToken(
            userId: 'user_1',
            token: 'fcm_token_abc',
            deviceType: 'android',
          ),
          throwsA(isA<FunctionException>()),
        );
      });
    });

    group('deleteToken', () {
      test('invokes EF with delete_token action', () async {
        when(
          () => mockFunctions.invoke(
            'user-manage-settings',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: jsonEncode({'success': true}),
          ),
        );

        await expectLater(
          repository.deleteToken('fcm_token_abc'),
          completes,
        );

        final captured = verify(
          () => mockFunctions.invoke(
            'user-manage-settings',
            body: captureAny(named: 'body'),
          ),
        ).captured;

        final body = captured.first as Map<String, dynamic>;
        expect(body['action'], 'delete_token');
        expect(body['token'], 'fcm_token_abc');
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
          'marketing_consent': false,
          'service_notification': true,
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
        mockTable(mockClient, 'user_settings');

        final result = await repository.getSettings('user_unknown');
        expect(result, isNull);
      });
    });

    group('updateSettings', () {
      test('invokes EF with update_settings action', () async {
        final settingsResponse = {
          'user_id': 'user_1',
          'marketing_consent': true,
          'service_notification': true,
          'updated_at': now.toIso8601String(),
        };

        when(
          () => mockFunctions.invoke(
            'user-manage-settings',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 200,
            data: jsonEncode({
              'success': true,
              'settings': settingsResponse,
            }),
          ),
        );

        final result = await repository.updateSettings(
          'user_1',
          {'marketing_consent': true},
        );

        expect(result, isNotNull);
        expect(result!.marketingConsent, true);

        final captured = verify(
          () => mockFunctions.invoke(
            'user-manage-settings',
            body: captureAny(named: 'body'),
          ),
        ).captured;

        final body = captured.first as Map<String, dynamic>;
        expect(body['action'], 'update_settings');
        expect(body['settings'], {'marketing_consent': true});
      });

      test('throws on EF error', () async {
        when(
          () => mockFunctions.invoke(
            'user-manage-settings',
            body: any(named: 'body'),
          ),
        ).thenAnswer(
          (_) async => FunctionResponse(
            status: 400,
            data: jsonEncode({'error': 'Invalid'}),
          ),
        );

        expect(
          () => repository.updateSettings(
            'user_1',
            {'marketing_consent': true},
          ),
          throwsA(isA<FunctionException>()),
        );
      });
    });
  });
}
