part of 'verification_repository.dart';

mixin _VerificationQueryRepository on _SupabaseVerificationContext {
  Future<List<Verification>> getPartnerVerifications(
    String partnerId, {
    bool isActive = true,
  }) async {
    Log.d(
      'getPartnerVerifications called | partnerId: $partnerId,'
      ' isActive: $isActive',
    );
    try {
      final data = await supabaseClient
          .from('verifications')
          .select()
          .eq('partner_id', partnerId)
          .eq('is_active', isActive)
          .order('created_at', ascending: false);

      final result = <Verification>[];
      for (final e in data as List) {
        try {
          result.add(Verification.fromJson(e as Map<String, dynamic>));
        } on Object catch (parseError) {
          Log.w(
            '⚠️ [VerificationRepo] Skipping invalid'
            ' verification record: $parseError',
          );
        }
      }

      Log.d('getPartnerVerifications success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] getPartnerVerifications Error', e, st);
      rethrow;
    }
  }

  Future<List<Verification>> getGlobalVerifications() async {
    Log.d('getGlobalVerifications called');
    try {
      final data = await supabaseClient
          .from('verifications')
          .select()
          .filter('partner_id', 'is', null)
          .eq('is_active', true)
          .order('display_name', ascending: true);

      final result = <Verification>[];
      for (final e in data as List) {
        try {
          result.add(Verification.fromJson(e as Map<String, dynamic>));
        } on Object catch (parseError) {
          Log.w(
            '⚠️ [VerificationRepo] Skipping invalid'
            ' verification record: $parseError',
          );
        }
      }

      Log.d('getGlobalVerifications success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] getGlobalVerifications Error', e, st);
      rethrow;
    }
  }

  Future<Verification?> getVerificationById(String id) async {
    Log.d('getVerificationById called | id: $id');
    try {
      final data = await supabaseClient
          .from('verifications')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (data == null) {
        Log.d('getVerificationById success | result: null');
        return null;
      }
      final result = Verification.fromJson(data);
      Log.d('getVerificationById success | name: ${result.displayName}');
      return result;
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] getVerificationById Error', e, st);
      rethrow;
    }
  }

  Future<List<Verification>> getVerificationsByIds(List<String> ids) async {
    Log.d('getVerificationsByIds called | ids: $ids');
    if (ids.isEmpty) return [];
    try {
      final data = await supabaseClient
          .from('verifications')
          .select()
          .inFilter('id', ids);

      final result = <Verification>[];
      for (final e in data as List) {
        try {
          result.add(Verification.fromJson(e as Map<String, dynamic>));
        } on Object catch (parseError) {
          Log.w(
            '⚠️ [VerificationRepo] Skipping invalid'
            ' verification record: $parseError',
          );
        }
      }

      Log.d('getVerificationsByIds success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] getVerificationsByIds Error', e, st);
      rethrow;
    }
  }

  Future<List<VerificationRequirementStatus>> getPartnerRequirementsStatus({
    required String partnerId,
    required List<String> requiredVerificationIds,
  }) async {
    Log.d(
      'getPartnerRequirementsStatus called | partnerId: $partnerId,'
      ' requiredIds: $requiredVerificationIds',
    );
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      Log.w('getPartnerRequirementsStatus: User not logged in');
      return [];
    }

    try {
      final masters = await supabaseClient
          .from('verifications')
          .select()
          .inFilter('id', requiredVerificationIds);

      final originalDatas = await supabaseClient
          .from('user_verifications')
          .select()
          .eq('user_id', userId)
          .inFilter('verification_id', requiredVerificationIds);

      final activeSubmissions = await supabaseClient
          .from('verification_submissions')
          .select()
          .eq('user_id', userId)
          .eq('partner_id', partnerId)
          .inFilter('verification_id', requiredVerificationIds)
          .order('created_at', ascending: false);

      final verifiedResults = await supabaseClient
          .from('partner_verified_users')
          .select()
          .eq('user_id', userId)
          .eq('partner_id', partnerId)
          .inFilter('verification_id', requiredVerificationIds);

      final result = <VerificationRequirementStatus>[];
      for (final dynamic m in masters as List) {
        try {
          final map = m as Map<String, dynamic>;
          final vId = map['id'];

          final original = (originalDatas as List)
              .cast<Map<String, dynamic>?>()
              .firstWhere(
                (d) => d?['verification_id'] == vId,
                orElse: () => null,
              );

          final submissionMap = (activeSubmissions as List)
              .cast<Map<String, dynamic>?>()
              .firstWhere(
                (r) => r?['verification_id'] == vId,
                orElse: () => null,
              );

          final submission = submissionMap != null
              ? VerificationSubmission.fromJson(submissionMap)
              : null;

          final verifiedResult = (verifiedResults as List)
              .cast<Map<String, dynamic>?>()
              .firstWhere(
                (res) => res?['verification_id'] == vId,
                orElse: () => null,
              );

          result.add(VerificationRequirementStatus(
            master: Verification.fromJson(map),
            userVerification: original,
            activeSubmission: submission,
            verifiedResult: verifiedResult,
          ));
        } on Object catch (parseError) {
          Log.w(
            '⚠️ [VerificationRepo] Skipping invalid'
            ' requirement status: $parseError',
          );
        }
      }

      Log.d('getPartnerRequirementsStatus success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] getPartnerRequirementsStatus Error', e, st);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingRequests(
    String partnerId,
  ) async {
    Log.d('getPendingRequests called | partnerId: $partnerId');
    try {
      final data = await supabaseClient.rpc<dynamic>(
        'get_pending_verification_requests_with_user',
        params: {'p_partner_id': partnerId},
      );
      // RPC returns flat columns: submission_id, partner_id, user_id,
      // verification_id, application_id, status, snapshot_data,
      // created_at, user_name

      // Map submission_id -> id and build nested user object
      // for UI compatibility
      final result = (data as List<dynamic>)
          .map((item) {
            final map = item as Map<String, dynamic>;
            return <String, dynamic>{
              ...map,
              'id': map['submission_id'],
              'user': {
                'id': map['user_id'],
                'name': map['user_name'],
                'email': '',
              },
            };
          })
          .toList()
          .cast<Map<String, dynamic>>();
      Log.d('getPendingRequests success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] getPendingRequests Error', e, st);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getRequestsByStatus(
    VerificationStatus status,
  ) async {
    Log.d('getRequestsByStatus called | status: $status');
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final statusName = status == VerificationStatus.needsCorrection
          ? 'needs_correction'
          : status.name;

      final data = await supabaseClient
          .from('verification_submissions')
          .select('*, partner:partners(*), verification:verifications(*)')
          .eq('user_id', userId)
          .eq('status', statusName)
          .order('updated_at', ascending: false);
      final result = (data as List<dynamic>).cast<Map<String, dynamic>>();
      Log.d('getRequestsByStatus success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] getRequestsByStatus Error', e, st);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getVerificationComments(
    String submissionId,
  ) async {
    Log.d('getVerificationComments called | submissionId: $submissionId');
    try {
      final data = await supabaseClient
          .from('verification_comments')
          .select()
          .eq('submission_id', submissionId)
          .order('created_at', ascending: true);
      final result = (data as List<dynamic>).cast<Map<String, dynamic>>();
      Log.d('getVerificationComments success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] getVerificationComments Error', e, st);
      rethrow;
    }
  }
}
