import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:path/path.dart' as p;
import '../utils/log.dart';

class PartnerService {
  final SupabaseClient _supabase;

  PartnerService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// 파트너 입점 신청 제출
  Future<void> submitApplication({
    required Map<String, dynamic> applicationData,
    required XFile bizRegistrationFile,
    required XFile bankbookFile,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw const AuthException('User not authenticated');

    Log.d('🚀 Submitting Partner Application for user: $userId');

    String? bizRegPath;
    String? bankbookPath;

    try {
      // 1. 서류 업로드 (partner-proofs 버킷)
      bizRegPath = await _uploadFile(userId, bizRegistrationFile, 'biz_reg');
      bankbookPath = await _uploadFile(userId, bankbookFile, 'bankbook');

      // 2. DB Insert
      await _supabase.from('partner_applications').insert({
        'user_id': userId,
        ...applicationData,
        'biz_registration_path': bizRegPath,
        'bankbook_path': bankbookPath,
        'status': 'pending',
      });

      Log.i('🎉 Partner application submitted successfully!');
    } catch (e, stackTrace) {
      Log.e('❌ Partner Application Failed', e, stackTrace);
      if (bizRegPath != null || bankbookPath != null) {
        await _supabase.storage.from('partner-proofs').remove([
          if (bizRegPath != null) bizRegPath,
          if (bankbookPath != null) bankbookPath,
        ]);
      }
      rethrow;
    }
  }

  Future<String> _uploadFile(String userId, XFile file, String type) async {
    final extension = p.extension(file.name);
    final path = '$userId/${type}_${DateTime.now().millisecondsSinceEpoch}$extension';
    final bytes = await file.readAsBytes();
    
    await _supabase.storage.from('partner-proofs').uploadBinary(
      path, 
      bytes,
      fileOptions: FileOptions(contentType: file.mimeType),
    );
    return path;
  }

  /// 내 신청 상태 확인
  Future<Map<String, dynamic>?> getMyApplication() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    return await _supabase
        .from('partner_applications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  // --- 관리자(Admin) 기능 ---

  /// 모든 입점 신청 목록 조회 (검색 및 필터 포함)
  Future<List<Map<String, dynamic>>> getAllApplications({
    String? status,
    String? searchTerm,
  }) async {
    var query = _supabase
        .from('partner_applications')
        .select('*, user:user_profiles(*)');

    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }

    if (searchTerm != null && searchTerm.isNotEmpty) {
      // 브랜드명 또는 사업자명으로 검색
      query = query.or('brand_name.ilike.%$searchTerm%,biz_name.ilike.%$searchTerm%');
    }

    return await query.order('created_at', ascending: false);
  }

  /// 입점 신청 심사 처리
  Future<void> reviewApplication({
    required String applicationId,
    required String status,
    String? adminComment,
  }) async {
    Log.d('⚖️ Reviewing Partner Application: ID=$applicationId, Status=$status');
    await _supabase.from('partner_applications').update({
      'status': status,
      'admin_comment': adminComment,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', applicationId);
  }

  // --- 멤버 권한 관리 기능 ---

  /// 파트너 소속 멤버 목록 조회
  Future<List<Map<String, dynamic>>> getPartnerMembers(String partnerId) async {
    return await _supabase
        .from('partner_member_permissions')
        .select('*, user:user_profiles(*)')
        .eq('partner_id', partnerId)
        .order('joined_at', ascending: true);
  }

  /// 멤버 역할(Role) 업데이트 (트리거에 의해 권한 자동 갱신됨)
  Future<void> updateMemberRole({
    required String partnerId,
    required String userId,
    required String role,
  }) async {
    Log.d('🎭 Updating Member Role: Partner=$partnerId, User=$userId, Role=$role');
    await _supabase
        .from('partner_member_permissions')
        .update({'role': role})
        .match({'partner_id': partnerId, 'user_id': userId});
  }

  /// 멤버 기능 권한(Permissions) 직접 업데이트 (커스텀 권한 부여 시)
  Future<void> updateMemberPermissions({
    required String partnerId,
    required String userId,
    required List<String> permissions,
  }) async {
    Log.d('⚙️ Updating Custom Permissions: Partner=$partnerId, User=$userId');
    await _supabase
        .from('partner_member_permissions')
        .update({'permissions': permissions})
        .match({'partner_id': partnerId, 'user_id': userId});
  }
}
