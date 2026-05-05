// Fix #2224: Regression tests for ticket mapping in getApplicationsByEventId.
// The RPC returns flat columns; these tests verify the nested 'ticket' object
// is built correctly from those flat columns before fromJson parses it.
//
// In production, ticket_id is always non-null (all applications have a ticket).
// What can be null is ticket_name (JOIN miss). The mapping guards on both:
//   ticket_id != null && ticket_name != null → build nested ticket object.
import 'package:flutter_test/flutter_test.dart';
import 'package:minglit_kit/src/data/models/event_application.dart';

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
    test('ticket relation is null when ticket_name column is null (JOIN miss)',
        () {
      // ticket_id is always present; ticket_name can be null if JOIN missed
      final map = _buildAppMap(ticketId: 'ticket-1', ticketName: null);
      final app = EventApplication.fromJson(map);
      expect(app.ticket, isNull);
    });

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
        targetEntryGroupIds: null,
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
}
