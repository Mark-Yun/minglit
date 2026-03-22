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
          .update({'is_active': false})
          .eq('id', verificationId);
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
          .update({'is_active': true})
          .eq('id', verificationId);
      Log.d('restoreVerification success');
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] restoreVerification Error', e, st);
      rethrow;
    }
  }

  // Fix #301: Split into EF calls — personal data save + partner submission
  Future<void> saveUserVerificationData({
    required String verificationId,
    required Map<String, dynamic> data,
  }) async {
    Log.d(
      'saveUserVerificationData called | verificationId: $verificationId',
    );
    try {
      final response = await supabaseClient.functions.invoke(
        'user-update-verification',
        body: {
          'verification_id': verificationId,
          'data': data,
        },
      );

      if (response.status != 200) {
        final respData = response.data;
        final errorMsg = respData is Map
            ? (respData['error'] as String?) ?? 'Failed to save verification'
            : 'Failed to save verification';
        throw MinglitUserException(errorMsg);
      }
      Log.d('saveUserVerificationData success');
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] saveUserVerificationData Error', e, st);
      rethrow;
    }
  }

  // Fix #301: Submit verification to partner via EF
  Future<String> submitVerificationToPartner({
    required String partnerId,
    required String verificationId,
    String? applicationId,
  }) async {
    Log.d(
      'submitVerificationToPartner called | partnerId: $partnerId,'
      ' verificationId: $verificationId',
    );
    try {
      final response = await supabaseClient.functions.invoke(
        'user-submit-verification',
        body: {
          'action': 'submit',
          'partner_id': partnerId,
          'verification_id': verificationId,
          // ignore: use_null_aware_elements, ?'key': val syntax causes invalid_null_aware_operator
          if (applicationId != null) 'application_id': applicationId,
        },
      );

      if (response.status != 200) {
        final respData = response.data;
        final errorMsg = respData is Map
            ? (respData['error'] as String?) ?? 'Failed to submit verification'
            : 'Failed to submit verification';
        throw MinglitUserException(errorMsg);
      }

      final data = response.data as Map<String, dynamic>;
      final submissionId = data['submission_id'] as String;
      Log.d('submitVerificationToPartner success | id: $submissionId');
      return submissionId;
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] submitVerificationToPartner Error', e, st);
      rethrow;
    }
  }

  // Fix #301: Combined save + submit (backward compatible replacement)
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
    try {
      // Step 1: Save personal data via EF
      await saveUserVerificationData(
        verificationId: verificationId,
        data: claimData,
      );
      // Step 2: Submit to partner via EF
      await submitVerificationToPartner(
        partnerId: partnerId,
        verificationId: verificationId,
      );
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
        await submitVerificationToPartner(
          partnerId: partnerId,
          verificationId: submission.verificationId,
        );
      }
      Log.d('submitBulkVerifications success');
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] submitBulkVerifications Error', e, st);
      rethrow;
    }
  }

  // Fix #301: will be replaced by partner-review-submission EF (#309)
  Future<void> reviewRequest({
    required String submissionId,
    required VerificationStatus status,
  }) async {
    Log.d(
      'reviewRequest called | submissionId: $submissionId, status: $status',
    );
    try {
      await supabaseClient
          .from('verification_submissions')
          .update({
            'status': status.name,
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': supabaseClient.auth.currentUser?.id,
          })
          .eq('id', submissionId);
      Log.d('reviewRequest success');
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] reviewRequest Error', e, st);
      rethrow;
    }
  }

  // Fix #301: submitComment via EF (verification_comments table dropped)
  Future<void> submitComment({
    required String submissionId,
    required Map<String, dynamic> content,
  }) async {
    Log.d('submitComment called | submissionId: $submissionId');
    try {
      final text = content['text'] as String? ?? '';
      final response = await supabaseClient.functions.invoke(
        'user-submit-verification',
        body: {
          'action': 'comment',
          'submission_id': submissionId,
          'text': text,
        },
      );

      if (response.status != 200) {
        final respData = response.data;
        final errorMsg = respData is Map
            ? (respData['error'] as String?) ?? 'Failed to submit comment'
            : 'Failed to submit comment';
        throw MinglitUserException(errorMsg);
      }
      Log.d('submitComment success');
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] submitComment Error', e, st);
      rethrow;
    }
  }
}
