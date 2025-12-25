import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:path/path.dart' as p;
import '../utils/log.dart';

enum VerificationCategory {
  career,
  asset,
  marriage,
  academic,
  vehicle,
  etc;

  String get value => name;
}

enum VerificationStatus {
  pending,
  approved,
  rejected;

  String get value => name;
}

class VerificationService {
  final SupabaseClient _supabase;

  VerificationService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// 인증 요청 제출 (Web/Mobile 하이브리드 지원)
  Future<void> submitRequest({
    required VerificationCategory category,
    required Map<String, dynamic> claimData,
    required List<XFile> proofFiles,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw const AuthException('User not authenticated');

    Log.d('🚀 Verification Submit: Category=${category.value}, User=$userId');

    List<String> uploadedPaths = [];

    try {
      // 1. Storage에 이미지 업로드
      for (var file in proofFiles) {
        final extension = p.extension(file.name);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
        final path = '$userId/$fileName';
        
        Log.d('📤 Uploading proof to: $path');
        
        final bytes = await file.readAsBytes();
        await _supabase.storage.from('verification-proofs').uploadBinary(
          path, 
          bytes,
          fileOptions: FileOptions(contentType: file.mimeType),
        );
        
        uploadedPaths.add(path);
        Log.d('✅ Upload success: $path');
      }

      // 2. DB에 요청 데이터 저장
      Log.d('💾 Inserting verification request to DB...');
      await _supabase.from('verification_requests').insert({
        'user_id': userId,
        'category': category.value,
        'claim_data': claimData,
        'proof_images': uploadedPaths,
      });
      Log.i('🎉 Verification request submitted successfully!');
    } catch (e, stackTrace) {
      Log.e('❌ Verification Submit Failed', e, stackTrace);
      
      if (uploadedPaths.isNotEmpty) {
        Log.w('🧹 Cleaning up orphan files...');
        await _supabase.storage.from('verification-proofs').remove(uploadedPaths);
      }
      rethrow;
    }
  }

  /// 특정 카테고리의 최신 요청 조회 (상태 상관 없이)
  Future<Map<String, dynamic>?> getActiveRequest(VerificationCategory category) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('verification_requests')
        .select()
        .eq('user_id', userId)
        .eq('category', category.value)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    
    return response;
  }

  /// 인증 요청 취소 (데이터 및 파일 삭제)
  Future<void> cancelRequest(String requestId) async {
    final request = await _supabase
        .from('verification_requests')
        .select('proof_images')
        .eq('id', requestId)
        .single();
    
    final List<dynamic> images = request['proof_images'] ?? [];
    final List<String> paths = images.map((e) => e.toString()).toList();

    if (paths.isNotEmpty) {
      await _supabase.storage.from('verification-proofs').remove(paths);
    }

    await _supabase.from('verification_requests').delete().eq('id', requestId);
  }

  /// 사용자의 인증 요청 내역 가져오기
  Future<List<Map<String, dynamic>>> getMyRequests() async {
    return await _supabase
        .from('verification_requests')
        .select()
        .order('created_at', ascending: false);
  }

  /// 대기 중인 모든 요청 조회 (Partner용)
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    return await _supabase
        .from('verification_requests')
        .select('*') // 조인 제거, 순수 요청 데이터만 조회
        .eq('status', 'pending')
        .order('created_at', ascending: true);
  }

  /// 요청 심사 처리 (Partner용)
  Future<void> reviewRequest({
    required String requestId,
    required VerificationStatus status,
    String? rejectionReason,
  }) async {
    final reviewerId = _supabase.auth.currentUser?.id;
    Log.d('⚖️ Reviewing Request: ID=$requestId, Status=${status.value}, Reviewer=$reviewerId');

    try {
      await _supabase.from('verification_requests').update({
        'status': status.value,
        'rejection_reason': rejectionReason,
        'reviewer_id': reviewerId,
        'verified_at': status == VerificationStatus.approved ? DateTime.now().toIso8601String() : null,
      }).eq('id', requestId);
      Log.i('✅ Review update successful');
    } catch (e, stackTrace) {
      Log.e('❌ Review Update Failed', e, stackTrace);
      rethrow;
    }
  }
}