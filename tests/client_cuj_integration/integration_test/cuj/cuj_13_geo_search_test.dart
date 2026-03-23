import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/e2e_auth.dart';
import '../utils/e2e_helpers.dart';

/// CUJ 13: 지리 검색 — 반경 내 이벤트 RPC 호출.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient adminClient;
  late String testEmail;

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();
    testEmail = await getTestUserEmail(adminClient, gender: 'male');
    await signInAsTestUser(testEmail);
  });

  tearDownAll(() async {
    await signOut();
  });

  group('CUJ 13: 지리 검색', () {
    testWidgets('get_events_within_radius RPC를 호출할 수 있다',
        (tester) async {
      final client = Supabase.instance.client;

      // Seoul coordinates
      final result = await client.rpc(
        'get_events_within_radius',
        params: {
          'p_lat': 37.5665,
          'p_lng': 126.9780,
          'p_radius_meters': 50000.0,
          'p_limit': 20,
        },
      );

      expect(result, isNotNull);
      expect(result, isA<List>());
    });

    testWidgets('검색 결과에 distance 필드가 포함된다', (tester) async {
      final client = Supabase.instance.client;

      final result = await client.rpc(
        'get_events_within_radius',
        params: {
          'p_lat': 37.5665,
          'p_lng': 126.9780,
          'p_radius_meters': 50000.0,
          'p_limit': 20,
        },
      ) as List;

      if (result.isNotEmpty) {
        for (final item in result) {
          final row = item as Map<String, dynamic>;
          expect(row.containsKey('id'), isTrue,
              reason: 'Each result must have an id field');
          // Verify at least one distance-related field is present
          final hasDistanceField =
              row.containsKey('distance') ||
              row.containsKey('distance_meters') ||
              row.containsKey('dist_meters');
          expect(hasDistanceField, isTrue,
              reason:
                  'Each result must have a distance-related field (distance, distance_meters, or dist_meters)');
        }
      }
    });

    testWidgets('반경 밖 좌표로 검색하면 결과가 적다', (tester) async {
      final client = Supabase.instance.client;

      // Seoul search — may return results
      final seoulResult = await client.rpc(
        'get_events_within_radius',
        params: {
          'p_lat': 37.5665,
          'p_lng': 126.9780,
          'p_radius_meters': 50000.0,
          'p_limit': 20,
        },
      ) as List;

      // Remote coordinates (Gulf of Guinea, far from Seoul)
      final remoteResult = await client.rpc(
        'get_events_within_radius',
        params: {
          'p_lat': 0.0,
          'p_lng': 0.0,
          'p_radius_meters': 50000.0,
          'p_limit': 20,
        },
      ) as List;

      expect(remoteResult.length, lessThanOrEqualTo(seoulResult.length),
          reason:
              'Remote coordinates should return fewer or equal results than Seoul');
    });
  });
}
