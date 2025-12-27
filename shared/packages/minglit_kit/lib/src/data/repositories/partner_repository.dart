import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:path/path.dart' as p;
import '../../utils/log.dart';
import '../models/partner_application.dart';

class PartnerRepository {
  final SupabaseClient _supabase;

  PartnerRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// 파트너 입점 신청 제출
  Future<void> submitApplication({
    required Map<String, dynamic> applicationData,
    required XFile bizRegistrationFile,
    required XFile bankbookFile,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw const AuthException('User not authenticated');

    Log.d('🚀 [PartnerRepo] Submitting Application for user: $userId');

    String? bizRegPath;
    String? bankbookPath;

    try {
      bizRegPath = await _uploadFile(userId, bizRegistrationFile, 'biz_reg');
      bankbookPath = await _uploadFile(userId, bankbookFile, 'bankbook');

      await _supabase.from('partner_applications').insert({
        'user_id': userId,
        ...applicationData,
        'biz_registration_path': bizRegPath,
        'bankbook_path': bankbookPath,
        'status': 'pending',
      });

      Log.i('🎉 [PartnerRepo] Application submitted successfully!');
    } catch (e, stackTrace) {
      Log.e('❌ [PartnerRepo] Application Failed', e, stackTrace);
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
  Future<PartnerApplication?> getMyApplication() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _supabase
        .from('partner_applications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
        
    if (data == null) return null;
    return PartnerApplication.fromJson(data);
  }

  /// 모든 입점 신청 목록 조회 (Admin)
  Future<List<PartnerApplication>> getAllApplications({
    String? status,
    String? searchTerm,
  }) async {
    var query = _supabase
        .from('partner_applications')
        .select();

    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }

    if (searchTerm != null && searchTerm.isNotEmpty) {
      query = query.or('brand_name.ilike.%$searchTerm%,biz_name.ilike.%$searchTerm%');
    }

    final List data = await query.order('created_at', ascending: false);
    return data.map((json) => PartnerApplication.fromJson(json)).toList();
  }

  /// 입점 신청 심사 처리 (Admin)
  Future<void> reviewApplication({
    required String applicationId,
    required String status,
    String? adminComment,
  }) async {
    Log.d('⚖️ [PartnerRepo] Reviewing Application: ID=$applicationId, Status=$status');
    await _supabase.from('partner_applications').update({
      'status': status,
      'admin_comment': adminComment,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', applicationId);
  }

  /// 파트너 소속 멤버 목록 조회
  Future<List<Map<String, dynamic>>> getPartnerMembers(String partnerId) async {
    return await _supabase
        .from('partner_member_permissions')
        .select('*, user:user_profiles(*)')
        .eq('partner_id', partnerId)
        .order('joined_at', ascending: true);
  }

  /// 멤버 역할(Role) 업데이트
  Future<void> updateMemberRole({
    required String partnerId,
    required String userId,
    required String role,
  }) async {
    Log.d('🎭 [PartnerRepo] Updating Role: Partner=$partnerId, User=$userId, Role=$role');
    await _supabase
        .from('partner_member_permissions')
        .update({'role': role})
        .match({'partner_id': partnerId, 'user_id': userId});
  }

  /// 멤버 기능 권한(Permissions) 직접 업데이트
  Future<void> updateMemberPermissions({
    required String partnerId,
    required String userId,
    required List<String> permissions,
  }) async {
    Log.d('⚙️ [PartnerRepo] Updating Custom Permissions: Partner=$partnerId, User=$userId');
    await _supabase
        .from('partner_member_permissions')
        .update({'permissions': permissions})
        .match({'partner_id': partnerId, 'user_id': userId});
  }
}
