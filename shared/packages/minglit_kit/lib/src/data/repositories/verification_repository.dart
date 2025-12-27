import 'package:image_picker/image_picker.dart' show XFile;
import 'package:minglit_kit/minglit_kit.dart' show Partner;
import 'package:minglit_kit/src/data/models/partner.dart' show Partner;
import 'package:minglit_kit/src/data/models/verification.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for handling user and partner verification logic.
class VerificationRepository {
  /// Creates a [VerificationRepository] with a [SupabaseClient].
  VerificationRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

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

    return (masters as List).map((dynamic m) {
      final map = m as Map<String, dynamic>;
      final vId = map['id'];
      final original = (originalDatas as List)
          .cast<Map<String, dynamic>?>()
          .firstWhere((d) => d?['verification_id'] == vId, orElse: () => null);
      final request = (activeRequests as List)
          .cast<Map<String, dynamic>?>()
          .firstWhere((r) => r?['verification_id'] == vId, orElse: () => null);
      final result = (verifiedResults as List)
          .cast<Map<String, dynamic>?>()
          .firstWhere(
            (res) => res?['verification_id'] == vId,
            orElse: () => null,
          );

      return VerificationRequirementStatus(
        master: map,
        originalData: original,
        activeRequest: request,
        verifiedResult: result,
      );
    }).toList();
  }

  /// [User] 인증 요청 제출 또는 재제출
  Future<void> submitOrUpdateVerification({
    required String partnerId,
    required String verificationId,
    required Map<String, dynamic> claimData,
    required List<XFile> proofFiles,
    String? existingRequestId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw const AuthException('User not authenticated');

    final uploadedPaths = <String>[];

    try {
      for (final file in proofFiles) {
        final extension = p.extension(file.name);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}$extension';
        final path = '$userId/$fileName';
        final bytes = await file.readAsBytes();

        await _supabase.storage
            .from('verification-proofs')
            .uploadBinary(path, bytes);
        uploadedPaths.add(path);
      }

      await _supabase.from('user_verifications').upsert({
        'user_id': userId,
        'verification_id': verificationId,
        'claim_data': claimData,
        'proof_images': uploadedPaths,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (existingRequestId != null) {
        await _supabase
            .from('verification_requests')
            .update({
              'status': VerificationStatus.resubmitted.name,
              'claim_snapshot': claimData,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingRequestId);
      } else {
        await _supabase.from('verification_requests').insert({
          'partner_id': partnerId,
          'user_id': userId,
          'verification_id': verificationId,
          'status': VerificationStatus.pending.name,
          'claim_snapshot': claimData,
        });
      }
    } on Exception catch (e, stackTrace) {
      Log.e('❌ [VerificationRepo] Submission Failed', e, stackTrace);
      rethrow;
    }
  }

  /// [Partner] 대기 중인 모든 요청 조회
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final data = await _supabase
        .from('verification_requests')
        .select('*, user:user_profiles!verification_requests_user_id_fkey(*)')
        .eq('status', 'pending')
        .order('created_at', ascending: true);
    return (data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// [Partner] 요청 심사 처리
  Future<void> reviewRequest({
    required String requestId,
    required VerificationStatus status,
    String? rejectionReason,
  }) async {
    final statusName =
        status == VerificationStatus.needsCorrection
            ? 'needs_correction'
            : status.name;

    await _supabase
        .from('verification_requests')
        .update({
          'status': statusName,
          'rejection_reason': rejectionReason,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId);
  }

  /// [User] 특정 상태의 모든 요청 조회 (예: 보완 필요 건만 모아보기)
  Future<List<Map<String, dynamic>>> getRequestsByStatus(
    VerificationStatus status,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final statusName =
        status == VerificationStatus.needsCorrection
            ? 'needs_correction'
            : status.name;

    final data = await _supabase
        .from('verification_requests')
        .select('*, partner:partners(*), verification:verifications(*)')
        .eq('user_id', userId)
        .eq('status', statusName)
        .order('updated_at', ascending: false);
    return (data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// Common: 인증 요청에 달린 코멘트 내역 조회
  Future<List<Map<String, dynamic>>> getVerificationComments(
    String requestId,
  ) async {
    final data = await _supabase
        .from('verification_comments')
        .select()
        .eq('request_id', requestId)
        .order('created_at', ascending: true);
    return (data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// Common: 코멘트 작성
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
}
