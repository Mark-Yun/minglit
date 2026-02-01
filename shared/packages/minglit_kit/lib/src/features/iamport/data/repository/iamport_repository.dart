import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'iamport_repository.g.dart';

@Riverpod(keepAlive: true)
IamportRepository iamportRepository(Ref ref) {
  return IamportRepository(Supabase.instance.client);
}

class IamportRepository {
  IamportRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<Map<String, dynamic>> verifyCertification(String impUid) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const MinglitAuthException('로그인이 필요합니다.');
    }

    try {
      Log.d('Calling verify-identity-v2 edge function...');

      final response = await _supabase.functions.invoke(
        'verify-identity-v2',
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
