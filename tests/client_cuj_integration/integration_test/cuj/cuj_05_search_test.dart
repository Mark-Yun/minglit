import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/e2e_auth.dart';
import '../utils/e2e_helpers.dart';

/// CUJ 05: Search — PGroonga full-text search for events and parties.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient adminClient;

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();

    final email = await getTestUserEmail(adminClient, gender: 'male');
    await signInAsTestUser(email);
  });

  tearDownAll(() async {
    await signOut();
  });

  group('CUJ 05: Search', () {
    testWidgets('이벤트 검색 RPC가 정상 동작한다', (tester) async {
      final client = Supabase.instance.client;

      final results = await retry(() async {
        return await client.rpc<List<dynamic>>(
          'search_events_pgroonga',
          params: {'query': '직장인'},
        );
      });

      expect(results, isList);
      if (results.isNotEmpty) {
        final first = results.first as Map<String, dynamic>;
        expect(first.containsKey('id'), isTrue);
        expect(first.containsKey('title'), isTrue);
      }
    });

    testWidgets('파티 검색 RPC가 정상 동작한다', (tester) async {
      final client = Supabase.instance.client;

      final results = await retry(() async {
        return await client.rpc<List<dynamic>>(
          'search_parties_pgroonga',
          params: {'query': '대학생'},
        );
      });

      expect(results, isList);
      if (results.isNotEmpty) {
        final first = results.first as Map<String, dynamic>;
        expect(first.containsKey('id'), isTrue);
        expect(first.containsKey('title'), isTrue);
      }
    });
  });
}
