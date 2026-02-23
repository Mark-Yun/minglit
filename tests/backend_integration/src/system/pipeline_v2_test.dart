// ignore_for_file: avoid_dynamic_calls -- PGMQ and RPC return dynamic types

import 'package:postgres/postgres.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';

import '../utils/test_config.dart';
import '../utils/test_database.dart';

void main() {
  final adminClient = SupabaseClient(
    TestConfig.supabaseUrl,
    TestConfig.serviceRoleKey,
    headers: {
      'Authorization': 'Bearer ${TestConfig.serviceRoleKey}',
      'apikey': TestConfig.serviceRoleKey,
    },
  );

  group('Pipeline V2: 2단계 큐 아키텍처 E2E', () {
    late Connection connection;

    setUpAll(() async {
      connection = await TestDatabase.createConnection();
    });

    tearDownAll(() async {
      await connection.close();
    });

    setUp(() async {
      // 각 테스트 전 모든 큐 비우기
      await connection.execute("SELECT pgmq.purge_queue('q_global_events')");
      await connection.execute("SELECT pgmq.purge_queue('q_notifications')");
      await connection.execute("SELECT pgmq.purge_queue('q_vectors')");
    });

    test(
        '1. party_created fan-out: '
        'q_notifications + q_vectors 양쪽에 메시지 도착', () async {
      const testId = '00000000-0000-4000-8000-000000000001';

      // produce_event 호출 → q_global_events → fanout trigger → 두 큐로 분배
      await adminClient.rpc('produce_event', params: {
        'p_event_type': 'party_created',
        'p_source_table': 'parties',
        'p_source_id': testId,
        'p_row_data': {'id': testId, 'title': 'Test Party for Fan-out'},
      });

      // q_notifications 확인
      final notifMsgs = await adminClient.rpc('pgmq_read', params: {
        'queue_name': 'q_notifications',
        'vt': 30,
        'limit': 5,
      });

      // q_vectors 확인
      final vectorMsgs = await adminClient.rpc('pgmq_read', params: {
        'queue_name': 'q_vectors',
        'vt': 30,
        'limit': 5,
      });

      expect(
        (notifMsgs as List).length,
        greaterThan(0),
        reason: 'party_created → q_notifications에 메시지가 있어야 함',
      );
      expect(
        (vectorMsgs as List).length,
        greaterThan(0),
        reason: 'party_created → q_vectors에도 메시지가 있어야 함',
      );
    });

    test(
        '2. application_approved selective fan-out: '
        'q_notifications에만 도착, q_vectors = 0', () async {
      const testId = '00000000-0000-4000-8000-000000000002';

      // produce_event 호출 → application_approved는 q_notifications만 라우팅
      await adminClient.rpc('produce_event', params: {
        'p_event_type': 'application_approved',
        'p_source_table': 'event_applications',
        'p_source_id': testId,
        'p_row_data': {'id': testId, 'user_id': testId},
      });

      final notifMsgs = await adminClient.rpc('pgmq_read', params: {
        'queue_name': 'q_notifications',
        'vt': 30,
        'limit': 5,
      });

      final vectorMsgs = await adminClient.rpc('pgmq_read', params: {
        'queue_name': 'q_vectors',
        'vt': 30,
        'limit': 5,
      });

      expect(
        (notifMsgs as List).length,
        greaterThan(0),
        reason: 'application_approved → q_notifications에 메시지가 있어야 함',
      );
      expect(
        (vectorMsgs as List).length,
        equals(0),
        reason: 'application_approved → q_vectors에 메시지가 없어야 함',
      );
    });

    test(
        '3. send_event_reminders: '
        "pgmq.send('q_notifications') 직접 호출 없음, produce_event 사용 확인", () async {
      // pg_get_functiondef로 함수 정의 검사
      final result = await connection.execute(
        "SELECT pg_get_functiondef(oid) "
        "FROM pg_proc "
        "WHERE proname = 'send_event_reminders'",
      );

      expect(
        result,
        isNotEmpty,
        reason: 'send_event_reminders 함수가 존재해야 함',
      );

      final funcDef = result.first[0]! as String;

      // 직접 pgmq.send('q_notifications') 호출이 없어야 함
      expect(
        funcDef.contains("pgmq.send('q_notifications')"),
        isFalse,
        reason:
            "send_event_reminders가 직접 pgmq.send('q_notifications')를 호출하면 안 됨",
      );

      // produce_event를 경유해야 함
      expect(
        funcDef.contains('produce_event'),
        isTrue,
        reason: 'send_event_reminders는 produce_event를 호출해야 함',
      );
    });
  });
}
