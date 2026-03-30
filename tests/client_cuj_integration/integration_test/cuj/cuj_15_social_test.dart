import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/e2e_auth.dart';
import '../utils/e2e_helpers.dart';

/// CUJ 15: 소셜 인터랙션 — 좋아요·북마크 추가 및 삭제.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient adminClient;
  late String testUserId;
  late String partnerId;

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();

    final email = await getTestUserEmail(adminClient, gender: 'male');
    await signInAsTestUser(email);
    testUserId = Supabase.instance.client.auth.currentUser!.id;

    // Find a partner to use as interaction target
    final partnerRes = await adminClient
        .from('partners')
        .select('id')
        .limit(1)
        .single();
    partnerId = partnerRes['id'] as String;

    // Cleanup any leftover interactions from previous runs
    await _cleanup(adminClient, testUserId);
  });

  tearDownAll(() async {
    await _cleanup(adminClient, testUserId);
    await signOut();
  });

  group('CUJ 15: 소셜 인터랙션', () {
    testWidgets('좋아요를 추가할 수 있다', (tester) async {
      // Try inserting via authenticated client first; RLS may allow it.
      final client = Supabase.instance.client;

      await client.from('social_interactions').insert({
        'user_id': testUserId,
        'target_id': partnerId,
        'target_type': 'partner',
        'interaction_type': 'like',
      });

      final rows = await client
          .from('social_interactions')
          .select()
          .eq('user_id', testUserId)
          .eq('target_id', partnerId)
          .eq('interaction_type', 'like') as List;

      expect(rows, isNotEmpty, reason: '좋아요 인터랙션이 생성되어야 한다');
    });

    testWidgets('좋아요 상태를 조회할 수 있다', (tester) async {
      final client = Supabase.instance.client;

      final rows = await client
          .from('social_interactions')
          .select()
          .eq('user_id', testUserId)
          .eq('target_id', partnerId)
          .eq('interaction_type', 'like') as List;

      expect(rows, isNotEmpty, reason: '좋아요가 존재해야 한다');

      final row = rows.first as Map<String, dynamic>;
      expect(row['target_type'], equals('partner'));
      expect(row['interaction_type'], equals('like'));
    });

    testWidgets('북마크를 추가할 수 있다', (tester) async {
      final client = Supabase.instance.client;

      await client.from('social_interactions').insert({
        'user_id': testUserId,
        'target_id': partnerId,
        'target_type': 'partner',
        'interaction_type': 'bookmark',
      });

      final rows = await client
          .from('social_interactions')
          .select()
          .eq('user_id', testUserId)
          .eq('target_id', partnerId)
          .eq('interaction_type', 'bookmark') as List;

      expect(rows, isNotEmpty, reason: '북마크 인터랙션이 생성되어야 한다');
    });

    testWidgets('좋아요를 삭제할 수 있다', (tester) async {
      final client = Supabase.instance.client;

      await client
          .from('social_interactions')
          .delete()
          .eq('user_id', testUserId)
          .eq('target_id', partnerId)
          .eq('interaction_type', 'like');

      final rows = await client
          .from('social_interactions')
          .select()
          .eq('user_id', testUserId)
          .eq('target_id', partnerId)
          .eq('interaction_type', 'like') as List;

      expect(rows, isEmpty, reason: '좋아요가 삭제되어야 한다');
    });

    testWidgets('북마크를 삭제할 수 있다', (tester) async {
      final client = Supabase.instance.client;

      await client
          .from('social_interactions')
          .delete()
          .eq('user_id', testUserId)
          .eq('target_id', partnerId)
          .eq('interaction_type', 'bookmark');

      final rows = await client
          .from('social_interactions')
          .select()
          .eq('user_id', testUserId)
          .eq('target_id', partnerId)
          .eq('interaction_type', 'bookmark') as List;

      expect(rows, isEmpty, reason: '북마크가 삭제되어야 한다');
    });
  });
}

Future<void> _cleanup(SupabaseClient admin, String userId) async {
  try {
    await admin
        .from('social_interactions')
        .delete()
        .eq('user_id', userId);
  } on Object catch (_) {}
}
