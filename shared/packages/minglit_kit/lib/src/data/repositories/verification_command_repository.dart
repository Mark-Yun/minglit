part of 'verification_repository.dart';

mixin _VerificationCommandRepository on _SupabaseVerificationContext {
  Future<Verification> createVerification(Verification verification) async {
    Log.d('createVerification called | name: ${verification.displayName}');
    try {
      final json = verification.toDbJson();

      final res = await supabaseClient
          .from('verifications')
          .insert(json)
          .select()
          .single();
      final result = Verification.fromJson(res);
      Log.d('createVerification success | id: ${result.id}');
      return result;
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] createVerification Error', e, st);
      rethrow;
    }
  }

  Future<void> updateVerification(Verification verification) async {
    Log.d('updateVerification called | id: ${verification.id}');
    try {
      final json = verification.toDbJson()..remove('partner_id');

      await supabaseClient
          .from('verifications')
          .update(json)
          .eq('id', verification.id);
      Log.d('updateVerification success');
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] updateVerification Error', e, st);
      rethrow;
    }
  }

  Future<void> deleteVerification(String verificationId) async {
    Log.d('deleteVerification called | verificationId: $verificationId');
    try {
      await supabaseClient
          .from('verifications')
          .update({'is_active': false}).eq('id', verificationId);
      Log.d('deleteVerification success');
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] deleteVerification Error', e, st);
      rethrow;
    }
  }

  Future<void> restoreVerification(String verificationId) async {
    Log.d('restoreVerification called | verificationId: $verificationId');
    try {
      await supabaseClient
          .from('verifications')
          .update({'is_active': true}).eq('id', verificationId);
      Log.d('restoreVerification success');
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] restoreVerification Error', e, st);
      rethrow;
    }
  }

  Future<void> submitOrUpdateVerification({
    required String partnerId,
    required String verificationId,
    required Map<String, dynamic> claimData,
    String? existingSubmissionId,
  }) async {
    Log.d(
      'submitOrUpdateVerification called | partnerId: $partnerId,'
      ' verificationId: $verificationId',
    );
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) throw const AuthException('User not authenticated');

    try {
      await supabaseClient.from('user_verifications').upsert({
        'user_id': userId,
        'verification_id': verificationId,
        'data': claimData,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (existingSubmissionId != null) {
        await supabaseClient.from('verification_submissions').update({
          'status': VerificationStatus.pending.name,
          'snapshot_data': claimData,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existingSubmissionId);
      } else {
        await supabaseClient.from('verification_submissions').insert({
          'partner_id': partnerId,
          'user_id': userId,
          'verification_id': verificationId,
          'status': VerificationStatus.pending.name,
          'snapshot_data': claimData,
        });
      }
      Log.d('submitOrUpdateVerification success');
    } on Exception catch (e, stackTrace) {
      Log.e('❌ [VerificationRepo] Submission Failed', e, stackTrace);
      rethrow;
    }
  }

  Future<void> submitBulkVerifications({
    required String partnerId,
    required List<VerificationSubmission> submissions,
  }) async {
    Log.d(
      'submitBulkVerifications called | partnerId: $partnerId,'
      ' count: ${submissions.length}',
    );
    try {
      for (final submission in submissions) {
        await submitOrUpdateVerification(
          partnerId: partnerId,
          verificationId: submission.verificationId,
          claimData: submission.snapshotData,
          existingSubmissionId: submission.id,
        );
      }
      Log.d('submitBulkVerifications success');
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] submitBulkVerifications Error', e, st);
      rethrow;
    }
  }

  Future<void> reviewRequest({
    required String submissionId,
    required VerificationStatus status,
    String? adminComment,
  }) async {
    Log.d(
      'reviewRequest called | submissionId: $submissionId, status: $status',
    );
    try {
      await supabaseClient.from('verification_submissions').update({
        'status': status.name,
        'admin_comment': adminComment,
        'reviewed_at': DateTime.now().toIso8601String(),
        'reviewed_by': supabaseClient.auth.currentUser?.id,
      }).eq('id', submissionId);
      Log.d('reviewRequest success');
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] reviewRequest Error', e, st);
      rethrow;
    }
  }

  Future<void> submitComment({
    required String submissionId,
    required Map<String, dynamic> content,
  }) async {
    Log.d('submitComment called | submissionId: $submissionId');
    final userId = supabaseClient.auth.currentUser?.id;
    try {
      await supabaseClient.from('verification_comments').insert({
        'submission_id': submissionId,
        'author_id': userId,
        'content': content,
      });
      Log.d('submitComment success');
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] submitComment Error', e, st);
      rethrow;
    }
  }
}
