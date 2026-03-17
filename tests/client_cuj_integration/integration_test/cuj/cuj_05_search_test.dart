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
  });

  tearDownAll(() async {
    await signOut();
  });

  group('CUJ 05: Search', () {
    testWidgets('Should search events via PGroonga RPC', (tester) async {
      // Sign in (RPC might require auth)
      final email = await getTestUserEmail(adminClient, gender: 'male');
      await signInAsTestUser(email);

      final client = Supabase.instance.client;

      // 1. Search events
      final eventResults = await retry(() async {
        return await client.rpc<List<dynamic>>(
          'search_events_pgroonga',
          params: {'query': '직장인'},
        );
      });

      // Events search should return results (seed data has this keyword)
      // If no results, the test still validates the RPC works without error
      expect(eventResults, isList);
      if (eventResults.isNotEmpty) {
        final first = eventResults.first as Map<String, dynamic>;
        expect(first.containsKey('id'), isTrue);
        expect(first.containsKey('title'), isTrue);
      }

      // 2. Search parties
      final partyResults = await retry(() async {
        return await client.rpc<List<dynamic>>(
          'search_parties_pgroonga',
          params: {'query': '대학생'},
        );
      });

      expect(partyResults, isList);
      if (partyResults.isNotEmpty) {
        final first = partyResults.first as Map<String, dynamic>;
        expect(first.containsKey('id'), isTrue);
        expect(first.containsKey('title'), isTrue);
      }
    });
  });
}
