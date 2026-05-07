// Fix #2224: Regression tests for ticket mapping in getApplicationsByEventId.
// The RPC returns flat columns; these tests verify the nested 'ticket' object
// is built correctly from those flat columns before fromJson parses it.
//
// In production, ticket_id is always non-null (all applications have a ticket).
// What can be null is ticket_name (JOIN miss). The mapping guards on both:
//   ticket_id != null && ticket_name != null → build nested ticket object.
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/event_application.dart';
import 'package:minglit_kit/src/data/repositories/event_repository.dart';

/// Simulates the appMap built by getApplicationsByEventId from a flat RPC row.
Map<String, dynamic> _buildAppMap({
  required String ticketId,
  String? ticketName,
  List<dynamic>? targetEntryGroupIds,
}) {
  return {
    'id': 'app-1',
    'event_id': 'event-1',
    'ticket_id': ticketId,
    'user_id': 'user-1',
    'payment_id': null,
    'payment_amount': 0,
    'status': 'pending_review',
    'created_at': '2026-01-01T00:00:00.000Z',
    'updated_at': '2026-01-01T00:00:00.000Z',
    'refund_status': 'none',
    'user': null,
    'submission': null,
    // Mirrors the mapping logic in event_repository_application_queries.dart
    'ticket': ticketName != null
        ? {
            'id': ticketId,
            'name': ticketName,
            'created_at': '2026-01-01T00:00:00.000Z',
            'updated_at': '2026-01-01T00:00:00.000Z',
            'target_entry_group_ids':
                targetEntryGroupIds?.map((e) => e.toString()).toList() ?? [],
          }
        : null,
  };
}

void main() {
  group('getApplicationsByEventId ticket mapping', () {
    test(
      'ticket relation is null when ticket_name column is null (JOIN miss)',
      () {
        // ticket_id is always present; ticket_name can be null if JOIN missed
        final map = _buildAppMap(ticketId: 'ticket-1');
        final app = EventApplication.fromJson(map);
        expect(app.ticket, isNull);
      },
    );

    test('ticket relation is built when ticket_name is present', () {
      final map = _buildAppMap(
        ticketId: 'ticket-1',
        ticketName: '일반 티켓',
        targetEntryGroupIds: [],
      );
      final app = EventApplication.fromJson(map);
      expect(app.ticket, isNotNull);
      expect(app.ticket!.id, 'ticket-1');
      expect(app.ticket!.name, '일반 티켓');
    });

    test(
      'target_entry_group_ids UUIDs are converted to strings correctly',
      () {
        const groupId = '550e8400-e29b-41d4-a716-446655440000';
        final map = _buildAppMap(
          ticketId: 'ticket-1',
          ticketName: '남성 티켓',
          targetEntryGroupIds: [groupId],
        );
        final app = EventApplication.fromJson(map);
        expect(app.ticket!.targetEntryGroupIds, [groupId]);
      },
    );

    test('target_entry_group_ids defaults to empty list when null', () {
      final map = _buildAppMap(
        ticketId: 'ticket-1',
        ticketName: '여성 티켓',
      );
      final app = EventApplication.fromJson(map);
      expect(app.ticket!.targetEntryGroupIds, isEmpty);
    });

    test('multiple target_entry_group_ids are all preserved', () {
      const ids = [
        '550e8400-e29b-41d4-a716-446655440001',
        '550e8400-e29b-41d4-a716-446655440002',
      ];
      final map = _buildAppMap(
        ticketId: 'ticket-1',
        ticketName: '커플 티켓',
        targetEntryGroupIds: ids,
      );
      final app = EventApplication.fromJson(map);
      expect(app.ticket!.targetEntryGroupIds, ids);
    });
  });

  // Fix #2224: exercises the actual flat-RPC → nested ticket transformation
  // in mapEventApplicationRpcRow. The tests above only verify fromJson with a
  // pre-nested map; this group ensures the mapping step itself is covered.
  group('mapEventApplicationRpcRow flat-to-nested transformation', () {
    Map<String, dynamic> flatRow({
      String ticketId = 'ticket-1',
      String? ticketName,
      List<dynamic>? targetEntryGroupIds,
      // Fix #2272: terminal timestamps, email, and username added to RPC
      String? paidAt,
      String? refundedAt,
      String? userEmail,
      String? userUsername,
    }) {
      return {
        'application_id': 'app-1',
        'event_id': 'event-1',
        'ticket_id': ticketId,
        'ticket_name': ticketName,
        'ticket_created_at': '2026-01-01T00:00:00.000Z',
        'ticket_updated_at': '2026-01-01T00:00:00.000Z',
        'target_entry_group_ids': targetEntryGroupIds,
        'user_id': 'user-1',
        'user_name': null,
        'user_phone': null,
        'user_email': userEmail,
        // Fix #2272: user_username is the real nickname; was previously missing
        // causing user_email to be stored in username slot (model contamination).
        'user_username': userUsername,
        'payment_id': null,
        'payment_amount': 0,
        'status': 'pending_review',
        'created_at': '2026-01-01T00:00:00.000Z',
        'updated_at': '2026-01-01T00:00:00.000Z',
        'paid_at': paidAt,
        'refunded_at': refundedAt,
        'refund_status': 'none',
      };
    }

    test('builds nested ticket from flat columns', () {
      final mapped = mapEventApplicationRpcRow(
        flatRow(ticketName: '일반 티켓'),
      );
      final app = EventApplication.fromJson(mapped);
      expect(app.ticket, isNotNull);
      expect(app.ticket!.id, 'ticket-1');
      expect(app.ticket!.name, '일반 티켓');
    });

    test('ticket is null when ticket_name is null (JOIN miss)', () {
      final mapped = mapEventApplicationRpcRow(flatRow());
      final app = EventApplication.fromJson(mapped);
      expect(app.ticket, isNull);
    });

    test('parses target_entry_group_ids from flat RPC list', () {
      const groupId = '550e8400-e29b-41d4-a716-446655440000';
      final mapped = mapEventApplicationRpcRow(
        flatRow(ticketName: '그룹 티켓', targetEntryGroupIds: [groupId]),
      );
      final app = EventApplication.fromJson(mapped);
      expect(app.ticket!.targetEntryGroupIds, [groupId]);
    });

    test('target_entry_group_ids defaults to empty when null in RPC row', () {
      final mapped = mapEventApplicationRpcRow(
        flatRow(ticketName: '일반 티켓'),
      );
      final app = EventApplication.fromJson(mapped);
      expect(app.ticket!.targetEntryGroupIds, isEmpty);
    });

    // Fix #2272: terminal timestamp and email mapping tests
    test('paid_at is mapped when present in RPC row', () {
      const ts = '2026-05-01T10:00:00.000Z';
      final mapped = mapEventApplicationRpcRow(
        flatRow(ticketName: '티켓', paidAt: ts),
      );
      final app = EventApplication.fromJson(mapped);
      expect(app.paidAt, DateTime.parse(ts));
    });

    test('paid_at is null when absent from RPC row', () {
      final mapped = mapEventApplicationRpcRow(flatRow(ticketName: '티켓'));
      final app = EventApplication.fromJson(mapped);
      expect(app.paidAt, isNull);
    });

    test('refunded_at is mapped when present in RPC row', () {
      const ts = '2026-05-02T15:30:00.000Z';
      final mapped = mapEventApplicationRpcRow(
        flatRow(ticketName: '티켓', refundedAt: ts),
      );
      final app = EventApplication.fromJson(mapped);
      expect(app.refundedAt, DateTime.parse(ts));
    });

    test('refunded_at is null when absent from RPC row', () {
      final mapped = mapEventApplicationRpcRow(flatRow(ticketName: '티켓'));
      final app = EventApplication.fromJson(mapped);
      expect(app.refundedAt, isNull);
    });

    // Fix #2272: username comes from user_username column (nickname), not email.
    // email was previously stored in username slot causing model contamination.
    test('user_username is stored in username field (Fix #2272)', () {
      final mapped = mapEventApplicationRpcRow(
        flatRow(
          ticketName: '티켓',
          userUsername: '코딩고수',
        )..['user_name'] = '테스트',
      );
      final app = EventApplication.fromJson(mapped);
      expect(app.user?.username, '코딩고수');
    });

    test('user_email does NOT contaminate username field (Fix #2272)', () {
      final mapped = mapEventApplicationRpcRow(
        flatRow(
          ticketName: '티켓',
          userEmail: 'test@example.com',
          userUsername: null,
        )..['user_name'] = '테스트',
      );
      final app = EventApplication.fromJson(mapped);
      // email must not leak into the username slot
      expect(app.user?.username, isNot(contains('@')));
      expect(app.user?.username, '');
    });

    test('username is empty string when user_username is null', () {
      final mapped = mapEventApplicationRpcRow(
        flatRow(ticketName: '티켓')..['user_name'] = '테스트',
      );
      final app = EventApplication.fromJson(mapped);
      expect(app.user?.username, '');
    });
  });
}
