import 'package:minglit_kit/src/utils/exceptions.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'iamport_repository.g.dart';

/// Provides the [IamportRepository] instance.
@Riverpod(keepAlive: true)
IamportRepository iamportRepository(Ref ref) {
  return IamportRepository(Supabase.instance.client);
}

/// Handles Iamport certification verification requests.
class IamportRepository {
  /// Creates a repository backed by the given Supabase client.
  IamportRepository(this._supabase);

  final SupabaseClient _supabase;

  /// Verifies a certification using the provided [impUid].
  Future<Map<String, dynamic>> verifyCertification(String impUid) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const MinglitAuthException('로그인이 필요합니다.');
    }

    try {
      Log.d('Calling identity-verify edge function...');

      final response = await _supabase.functions.invoke(
        'identity-verify',
        body: {'identity_verification_id': impUid},
      );

      if (response.status != 200) {
        throw const MinglitUserException('본인 인증 검증에 실패했습니다.');
      }

      if (response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data as Map);
      }

      return {'result': response.data};
    } on Object catch (e, st) {
      Log.e('❌ [IamportRepository] verifyCertification Error', e, st);
      rethrow;
    }
  }
}
