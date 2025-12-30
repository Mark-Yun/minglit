import 'package:minglit_kit/src/data/models/verification.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'verification_repository.g.dart';

/// Provider for VerificationRepository.
@Riverpod(keepAlive: true)
VerificationRepository verificationRepository(Ref ref) {
  return SupabaseVerificationRepository();
}

/// Data Transfer Object for verification submission.
class VerificationSubmission {
  /// Creates a [VerificationSubmission] instance.
  VerificationSubmission({
    required this.verificationId,
    required this.claimData,
    this.existingRequestId,
  });

  /// The ID of the verification definition.
  final String verificationId;

  /// The data being claimed (key-value pairs).
  final Map<String, dynamic> claimData;

  /// Optional: Existing submission ID to update.
  final String? existingRequestId;
}

/// Repository for handling user and partner verification logic.
abstract class VerificationRepository {
  // --- Partner Management (Create/Edit Verifications) ---

  /// Creates a new verification requirement for a partner.
  Future<Verification> createVerification(Verification verification);

  /// Updates an existing verification.
  Future<void> updateVerification(Verification verification);

  /// Soft-deletes a verification (sets is_active = false).
  Future<void> deleteVerification(String verificationId);

  /// Fetches verifications created by a specific partner (Active only).
  Future<List<Verification>> getPartnerVerifications(String partnerId);

  /// Fetches global (system) verifications (Active only).
  Future<List<Verification>> getGlobalVerifications();

  /// Fetches a specific verification by ID.
  Future<Verification?> getVerificationById(String id);

  // --- User Flow (Requirements & Status) ---

  /// User 특정 파트너가 요구하는 인증들의 상태를 일괄 조회
  Future<List<VerificationRequirementStatus>> getPartnerRequirementsStatus({
    required String partnerId,
    required List<String> requiredVerificationIds,
  });

  /// User 인증 데이터 저장 및 파트너에게 제출 (Snapshot 복사)
  Future<void> submitOrUpdateVerification({
    required String partnerId,
    required String verificationId,
    required Map<String, dynamic> claimData,
    String? existingSubmissionId,
  });

  /// User 다수의 인증 요청을 일괄 제출
  Future<void> submitBulkVerifications({
    required String partnerId,
    required List<VerificationSubmission> submissions,
  });

  // --- Partner Flow (Review) ---

  /// Partner 대기 중인 모든 요청 조회
  Future<List<Map<String, dynamic>>> getPendingRequests();

  /// Partner 요청 심사 처리
  Future<void> reviewRequest({
    required String submissionId,
    required VerificationStatus status,
    String? adminComment,
  });

  /// User 특정 상태의 모든 요청 조회 (예: 보완 필요 건만 모아보기)
  Future<List<Map<String, dynamic>>> getRequestsByStatus(
    VerificationStatus status,
  );

  /// Common: 인증 요청에 달린 코멘트 내역 조회
  Future<List<Map<String, dynamic>>> getVerificationComments(
    String submissionId,
  );

  /// Common: 코멘트 작성
  Future<void> submitComment({
    required String submissionId,
    required Map<String, dynamic> content,
  });
}

/// Concrete implementation of [VerificationRepository] using Supabase.
class SupabaseVerificationRepository implements VerificationRepository {
  /// Creates a [SupabaseVerificationRepository] with a [SupabaseClient].
  SupabaseVerificationRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  @override
  Future<Verification> createVerification(Verification verification) async {
    final json = verification.toJson()
      ..remove('id')
      ..remove('created_at');

    final res = await _supabase
        .from('verifications')
        .insert(json)
        .select()
        .single();
    return Verification.fromJson(res);
  }

  @override
  Future<void> updateVerification(Verification verification) async {
    final json = verification.toJson()
      ..remove('id')
      ..remove('created_at')
      ..remove('partner_id');

    await _supabase
        .from('verifications')
        .update(json)
        .eq('id', verification.id);
  }

  @override
  Future<void> deleteVerification(String verificationId) async {
    await _supabase
        .from('verifications')
        .update({'is_active': false})
        .eq('id', verificationId);
  }

  @override
  Future<List<Verification>> getPartnerVerifications(String partnerId) async {
    final data = await _supabase
        .from('verifications')
        .select()
        .eq('partner_id', partnerId)
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => Verification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Verification>> getGlobalVerifications() async {
    final data = await _supabase
        .from('verifications')
        .select()
        .filter('partner_id', 'is', null)
        .eq('is_active', true)
        .order('display_name', ascending: true);

    return (data as List)
        .map((e) => Verification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Verification?> getVerificationById(String id) async {
    final data = await _supabase
        .from('verifications')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return Verification.fromJson(data);
  }

  @override
  Future<List<VerificationRequirementStatus>> getPartnerRequirementsStatus({
    required String partnerId,
    required List<String> requiredVerificationIds,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final masters = await _supabase
        .from('verifications')
        .select()
        .inFilter('id', requiredVerificationIds);

    final originalDatas = await _supabase
        .from('user_verifications')
        .select()
        .eq('user_id', userId)
        .inFilter('verification_id', requiredVerificationIds);

    final activeSubmissions = await _supabase
        .from('verification_submissions')
        .select()
        .eq('user_id', userId)
        .eq('partner_id', partnerId)
        .inFilter('verification_id', requiredVerificationIds)
        .order('created_at', ascending: false);

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

      final submission = (activeSubmissions as List)
          .cast<Map<String, dynamic>?>()
          .firstWhere((r) => r?['verification_id'] == vId, orElse: () => null);

      final result = (verifiedResults as List)
          .cast<Map<String, dynamic>?>()
          .firstWhere(
            (res) => res?['verification_id'] == vId,
            orElse: () => null,
          );

      return VerificationRequirementStatus(
        master: Verification.fromJson(map),
        userVerification: original,
        activeSubmission: submission,
        verifiedResult: result,
      );
    }).toList();
  }

  @override
  Future<void> submitOrUpdateVerification({
    required String partnerId,
    required String verificationId,
    required Map<String, dynamic> claimData,
    String? existingSubmissionId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw const AuthException('User not authenticated');

    try {
      await _supabase.from('user_verifications').upsert({
        'user_id': userId,
        'verification_id': verificationId,
        'data': claimData,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (existingSubmissionId != null) {
        await _supabase
            .from('verification_submissions')
            .update({
              'status': VerificationStatus.pending.name,
              'snapshot_data': claimData,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingSubmissionId);
      } else {
        await _supabase.from('verification_submissions').insert({
          'partner_id': partnerId,
          'user_id': userId,
          'verification_id': verificationId,
          'status': VerificationStatus.pending.name,
          'snapshot_data': claimData,
        });
      }
    } on Exception catch (e, stackTrace) {
      Log.e('❌ [VerificationRepo] Submission Failed', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> submitBulkVerifications({
    required String partnerId,
    required List<VerificationSubmission> submissions,
  }) async {
    for (final submission in submissions) {
      await submitOrUpdateVerification(
        partnerId: partnerId,
        verificationId: submission.verificationId,
        claimData: submission.claimData,
        existingSubmissionId: submission.existingRequestId,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final data = await _supabase
        .from('verification_submissions')
        .select('*, user:user_profiles(*)')
        .eq('status', 'pending')
        .order('created_at', ascending: true);
    return (data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> reviewRequest({
    required String submissionId,
    required VerificationStatus status,
    String? adminComment,
  }) async {
    await _supabase
        .from('verification_submissions')
        .update({
          'status': status.name,
          'admin_comment': adminComment,
          'reviewed_at': DateTime.now().toIso8601String(),
          'reviewed_by': _supabase.auth.currentUser?.id,
        })
        .eq('id', submissionId);
  }

  @override
  Future<List<Map<String, dynamic>>> getRequestsByStatus(
    VerificationStatus status,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final statusName = status == VerificationStatus.needsCorrection
        ? 'needs_correction'
        : status.name;

    final data = await _supabase
        .from('verification_submissions')
        .select('*, partner:partners(*), verification:verifications(*)')
        .eq('user_id', userId)
        .eq('status', statusName)
        .order('updated_at', ascending: false);
    return (data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> getVerificationComments(
    String submissionId,
  ) async {
    final data = await _supabase
        .from('verification_comments')
        .select()
        .eq('submission_id', submissionId)
        .order('created_at', ascending: true);
    return (data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> submitComment({
    required String submissionId,
    required Map<String, dynamic> content,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    await _supabase.from('verification_comments').insert({
      'submission_id': submissionId,
      'author_id': userId,
      'content': content,
    });
  }
}
