import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/e2e_auth.dart';
import '../utils/e2e_helpers.dart';

/// CUJ 12: 추천 피드
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SupabaseClient adminClient;
  late String testEmail;
  late String testUserId;

  setUpAll(() async {
    await initializeE2E();
    adminClient = createAdminClient();
    testEmail = await getTestUserEmail(adminClient, gender: 'male');
    await signInAsTestUser(testEmail);
    testUserId = Supabase.instance.client.auth.currentUser!.id;
  });

  tearDownAll(() async {
    await signOut();
  });

  group('CUJ 12: 추천 피드', () {
    testWidgets('get_personalized_recommendations RPC를 호출할 수 있다',
        (tester) async {
      final client = Supabase.instance.client;

      final result = await client.rpc(
        'get_personalized_recommendations',
        params: {
          'p_user_id': testUserId,
          'p_limit': 10,
        },
      ) as List;

      // 임베딩이 없을 경우 빈 리스트도 유효한 결과다
      expect(result, isA<List>(), reason: 'RPC 결과는 리스트여야 한다');
    });

    testWidgets('추천 결과 데이터 구조가 올바르다', (tester) async {
      final client = Supabase.instance.client;

      final result = await client.rpc(
        'get_personalized_recommendations',
        params: {
          'p_user_id': testUserId,
          'p_limit': 10,
        },
      ) as List;

      if (result.isEmpty) {
        // 임베딩 데이터가 없으면 빈 결과는 정상이므로 스킵
        markTestSkipped('추천 결과가 없음: 임베딩 데이터 부족으로 결과가 비어 있어 구조 검증을 건너뜁니다.');
        return;
      }

      final first = result.first as Map<String, dynamic>;
      expect(first.containsKey('id'), isTrue, reason: "추천 항목에 'id' 필드가 있어야 한다");
      expect(
        first.containsKey('title'),
        isTrue,
        reason: "추천 항목에 'title' 필드가 있어야 한다",
      );
    });
  });
}
