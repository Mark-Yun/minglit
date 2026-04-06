import 'package:flutter_test/flutter_test.dart';

void main() {
  group('snapshot_data type guard', () {
    // Fix #1115 regression: type guard prevents TypeError when snapshot_data
    // contains non-map elements. Extracts the parsing logic from
    // _buildRequestCard for direct unit testing.
    Map<String, dynamic> parseLastSnapshotEntry(dynamic snapshotData) {
      final snapshotList = snapshotData is List ? snapshotData : <dynamic>[];
      final lastRaw = snapshotList.isNotEmpty ? snapshotList.last : null;
      return lastRaw is Map<String, dynamic> ? lastRaw : <String, dynamic>{};
    }

    test('returns empty map when snapshot_data is null', () {
      final result = parseLastSnapshotEntry(null);
      expect(result, isEmpty);
    });

    test('returns empty map when snapshot_data is not a List', () {
      final result = parseLastSnapshotEntry('not a list');
      expect(result, isEmpty);
    });

    test('returns empty map when snapshot_data is empty list', () {
      final result = parseLastSnapshotEntry(<dynamic>[]);
      expect(result, isEmpty);
    });

    test('returns empty map when last element is a String', () {
      final result = parseLastSnapshotEntry(<dynamic>['a']);
      expect(result, isEmpty);
    });

    test('returns empty map when last element is null', () {
      final result = parseLastSnapshotEntry(<dynamic>[null]);
      expect(result, isEmpty);
    });

    test('returns empty map when last element is an int', () {
      final result = parseLastSnapshotEntry(<dynamic>[42]);
      expect(result, isEmpty);
    });

    test('returns map when last element is a Map<String, dynamic>', () {
      final result = parseLastSnapshotEntry(<dynamic>[
        {
          'data': {'photo': 'url1'},
        },
      ]);
      expect(result, isA<Map<String, dynamic>>());
      expect(result['data'], isA<Map>());
    });

    test('returns empty map for last element non-map in mixed list', () {
      final result = parseLastSnapshotEntry(<dynamic>[
        {'ok': 1},
        'bad',
      ]);
      expect(result, isEmpty);
    });

    test('returns map for valid last element in mixed list', () {
      final result = parseLastSnapshotEntry(<dynamic>[
        'first',
        {
          'data': {'photo': 'url2'},
        },
      ]);
      expect(result, isA<Map<String, dynamic>>());
      expect(result['data'], isA<Map>());
    });
  });
}
