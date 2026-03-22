import 'package:minglit_kit/src/data/models/verification.dart';
import 'package:minglit_kit/src/data/models/verification_submission.dart';
import 'package:minglit_kit/src/utils/exceptions.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'verification_repository.g.dart';
part 'verification_query_repository.dart';
part 'verification_command_repository.dart';

/// Provider for VerificationRepository.
@Riverpod(keepAlive: true)
VerificationRepository verificationRepository(Ref ref) {
  return SupabaseVerificationRepository();
}

/// Fetches verifications by a comma-separated list of IDs.
@Riverpod(keepAlive: true)
Future<List<Verification>> verificationsByIds(
  Ref ref,
  String commaSeparatedIds,
) async {
  if (commaSeparatedIds.isEmpty) return [];
  final ids = commaSeparatedIds.split(',');
  final repo = ref.watch(verificationRepositoryProvider);
  return repo.getVerificationsByIds(ids);
}

// VerificationSubmission class removed (Use model from models/verification.dart)

/// Repository for handling user and partner verification logic.
abstract class VerificationRepository {
  // --- Partner Management (Create/Edit Verifications) ---

  /// Creates a new verification requirement for a partner.
  Future<Verification> createVerification(Verification verification);

  /// Updates an existing verification.
  Future<void> updateVerification(Verification verification);

  /// Soft-deletes a verification (sets is_active = false).
  Future<void> deleteVerification(String verificationId);

  /// Fetches verifications created by a specific partner.
  /// [isActive] defaults to true. Set to false to fetch archived ones.
  Future<List<Verification>> getPartnerVerifications(
    String partnerId, {
    bool isActive = true,
  });

  /// Restores an archived verification (sets is_active = true).
  Future<void> restoreVerification(String verificationId);

  /// Fetches global (system) verifications (Active only).
  Future<List<Verification>> getGlobalVerifications();

  /// Fetches a specific verification by ID.
  Future<Verification?> getVerificationById(String id);

  /// Fetches a list of verifications by their IDs.
  Future<List<Verification>> getVerificationsByIds(List<String> ids);

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
  Future<List<Map<String, dynamic>>> getPendingRequests(String partnerId);

  /// Partner 요청 심사 처리
  Future<void> reviewRequest({
    required String submissionId,
    required VerificationStatus status,
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
class SupabaseVerificationRepository extends _SupabaseVerificationContextBase
    with _VerificationQueryRepository, _VerificationCommandRepository
    implements VerificationRepository {
  /// Creates a [SupabaseVerificationRepository] with a [SupabaseClient].
  SupabaseVerificationRepository({SupabaseClient? supabase})
    : super(supabase ?? Supabase.instance.client);
}

abstract class _SupabaseVerificationContext {
  SupabaseClient get supabaseClient;
}

abstract class _SupabaseVerificationContextBase
    implements _SupabaseVerificationContext {
  const _SupabaseVerificationContextBase(this.supabaseClient);

  @override
  final SupabaseClient supabaseClient;
}
