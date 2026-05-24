import 'package:app_partner/src/features/admin/ops_cicd_status/ops_cicd_status_models.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final Provider<OpsCicdStatusRepository> opsCicdStatusRepositoryProvider =
    Provider<OpsCicdStatusRepository>((ref) {
      return OpsCicdStatusRepository(ref.watch(supabaseClientProvider));
    });

final FutureProvider<OpsCicdStatusSnapshot> opsCicdStatusSnapshotProvider =
    FutureProvider.autoDispose<OpsCicdStatusSnapshot>((ref) async {
      return ref.watch(opsCicdStatusRepositoryProvider).fetch();
    });

class OpsCicdStatusRepository {
  const OpsCicdStatusRepository(this._client);

  final SupabaseClient _client;

  Future<OpsCicdStatusSnapshot> fetch() async {
    final response = await _client.functions.invoke('ops-cicd-status');
    if (response.status != 200) {
      final data = response.data;
      final message = data is Map
          ? data['error'] as String? ?? 'CI/CD 상태를 불러오지 못했습니다.'
          : 'CI/CD 상태를 불러오지 못했습니다.';
      throw MinglitUserException(message);
    }

    final data = response.data;
    if (data is! Map) {
      throw const MinglitUserException('CI/CD 상태 응답 형식이 올바르지 않습니다.');
    }
    return OpsCicdStatusSnapshot.fromJson(Map<String, dynamic>.from(data));
  }
}
