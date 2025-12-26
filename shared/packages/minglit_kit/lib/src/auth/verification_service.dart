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
  rejected,
  needs_correction,
  resubmitted;

  String get value => name;
}

/// 특정 인증 항목의 종합 상태 정보를 담는 클래스
class VerificationRequirementStatus {
  final Map<String, dynamic> master; // verifications 테이블 정보
  final Map<String, dynamic>? originalData; // user_verifications (유저 원본)
  final Map<String, dynamic>? activeRequest; // verification_requests (진행중인 요청)
  final Map<String, dynamic>? verifiedResult; // partner_verified_users (최종 승인본)

  VerificationRequirementStatus({
    required this.master,
    this.originalData,
    this.activeRequest,
    this.verifiedResult,
  });

  bool get isApproved => verifiedResult != null;
  bool get hasActiveRequest => activeRequest != null;
  VerificationStatus? get status => activeRequest != null 
      ? VerificationStatus.values.byName(activeRequest!['status']) 
      : null;
}

class VerificationService {
  final SupabaseClient _supabase;

  VerificationService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// [User] 특정 파트너가 요구하는 인증들의 상태를 일괄 조회
  Future<List<VerificationRequirementStatus>> getPartnerRequirementsStatus({
    required String partnerId,
    required List<String> requiredVerificationIds,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    // 1. 인증 마스터 정보 조회
    final masters = await _supabase
        .from('verifications')
        .select()
        .inFilter('id', requiredVerificationIds);

    // 2. 유저 원본 데이터 조회
    final originalDatas = await _supabase
        .from('user_verifications')
        .select()
        .eq('user_id', userId)
        .inFilter('verification_id', requiredVerificationIds);

    // 3. 파트너에게 보낸 현재 요청 조회
    final activeRequests = await _supabase
        .from('verification_requests')
        .select()
        .eq('user_id', userId)
        .eq('partner_id', partnerId)
        .inFilter('verification_id', requiredVerificationIds);

    // 4. 이 파트너에게 이미 승인받은 결과 조회
    final verifiedResults = await _supabase
        .from('partner_verified_users')
        .select()
        .eq('user_id', userId)
        .eq('partner_id', partnerId)
        .inFilter('verification_id', requiredVerificationIds);

    // 데이터를 매핑하여 결과 생성
    return masters.map((m) {
      final vId = m['id'];
      return VerificationRequirementStatus(
        master: m,
        originalData: originalDatas.cast<Map<String, dynamic>?>().firstWhere((d) => d?['verification_id'] == vId, orElse: () => null),
        activeRequest: activeRequests.cast<Map<String, dynamic>?>().firstWhere((r) => r?['verification_id'] == vId, orElse: () => null),
        verifiedResult: verifiedResults.cast<Map<String, dynamic>?>().firstWhere((res) => res?['verification_id'] == vId, orElse: () => null),
      );
    }).toList();
  }

  /// [Common] 인증 요청에 달린 코멘트 내역 조회
  Future<List<Map<String, dynamic>>> getVerificationComments(String requestId) async {
    return await _supabase
        .from('verification_comments')
        .select()
        .eq('request_id', requestId)
        .order('created_at', ascending: true);
  }

  /// [Common] 코멘트 작성
  Future<void> submitComment({
    required String requestId,
    required Map<String, dynamic> content,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    await _supabase.from('verification_comments').insert({
      'request_id': requestId,
      'author_id': userId,
      'content': content,
    });
  }

  /// [User] 인증 요청 제출 또는 재제출 (수정 포함)
  Future<void> submitOrUpdateVerification({
    required String partnerId,
    required String verificationId,
    required Map<String, dynamic> claimData,
    required List<XFile> proofFiles,
    String? existingRequestId, // 재제출일 경우 ID 전달
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw const AuthException('User not authenticated');

    List<String> uploadedPaths = [];

    try {
      // 1. 파일 업로드 (새 파일이 있는 경우만)
      for (var file in proofFiles) {
        // 이미 업로드된 경로(string)인 경우 스킵하는 로직은 호출부에서 처리
        final extension = p.extension(file.name);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
        final path = '$userId/$fileName';
        final bytes = await file.readAsBytes();
        
        await _supabase.storage.from('verification-proofs').uploadBinary(path, bytes);
        uploadedPaths.add(path);
      }

      // 2. 유저 원본 데이터 업데이트 (재사용성 확보)
      await _supabase.from('user_verifications').upsert({
        'user_id': userId,
        'verification_id': verificationId,
        'claim_data': claimData,
        'proof_images': uploadedPaths, // 일단은 단순화하여 전체 교체 방식
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 3. 심사 요청 테이블 생성 또는 업데이트
      if (existingRequestId != null) {
        // 보완 후 재제출
        await _supabase.from('verification_requests').update({
          'status': VerificationStatus.resubmitted.value,
          'claim_snapshot': claimData,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existingRequestId);
      } else {
        // 신규 제출
        await _supabase.from('verification_requests').insert({
          'partner_id': partnerId,
          'user_id': userId,
          'verification_id': verificationId,
          'status': VerificationStatus.pending.value,
          'claim_snapshot': claimData,
        });
      }
    } catch (e, stackTrace) {
      Log.e('❌ Verification Submission Failed', e, stackTrace);
      rethrow;
    }
  }

  /// [User] 특정 상태의 모든 요청 조회 (예: 보완 필요 건만 모아보기)
  Future<List<Map<String, dynamic>>> getRequestsByStatus(VerificationStatus status) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    return await _supabase
        .from('verification_requests')
        .select('*, partner:partners(*), verification:verifications(*)')
        .eq('user_id', userId)
        .eq('status', status.value)
        .order('updated_at', ascending: false);
  }

  /// [Partner] 대기 중인 모든 요청 조회 (유저 프로필 포함)
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    return await _supabase
        .from('verification_requests')
        .select('*, user:user_profiles!verification_requests_user_id_fkey(*)')
        .eq('status', 'pending')
        .order('created_at', ascending: true);
  }

  /// [Partner] 요청 심사 처리 (승인/반려/보완요청)
  Future<void> reviewRequest({
    required String requestId,
    required VerificationStatus status,
    String? rejectionReason,
  }) async {
    await _supabase.from('verification_requests').update({
      'status': status.value,
      'rejection_reason': rejectionReason,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  /// 인증 요청 취소 (데이터 및 파일 삭제)
  Future<void> cancelRequest(String requestId) async {
    final request = await _supabase
        .from('verification_requests')
        .select('claim_snapshot') // 스냅샷에서 파일 경로를 찾아야 할 수도 있음 (현재는 proof_images가 원본에만 있음)
        .eq('id', requestId)
        .single();
    
    // 이 부분은 나중에 스냅샷 구조에 따라 정교화 필요
    await _supabase.from('verification_requests').delete().eq('id', requestId);
  }
}
