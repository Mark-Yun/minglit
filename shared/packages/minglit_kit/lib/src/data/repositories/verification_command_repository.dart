part of 'verification_repository.dart';

mixin _VerificationCommandRepository on _SupabaseVerificationContext {
  // Fix #308: createVerification via EF (partner_id 서버 검증)
  Future<Verification> createVerification(Verification verification) async {
    Log.d('createVerification called | name: ${verification.displayName}');
    try {
      final response = await supabaseClient.functions.invoke(
        'partner-manage-verification',
        body: {
          'action': 'create',
          'partner_id': verification.partnerId,
          'category': verification.category.name,
          'internal_name': verification.internalName,
          'display_name': verification.displayName,
          if (verification.description != null)
            'description': verification.description,
          if (verification.iconKey != null) 'icon_key': verification.iconKey,
          'form_schema': verification.formSchema
              .map((f) => f.toJson())
              .toList(),
        },
      );

      if (response.status != 200) {
        final respData = response.data;
        final errorMsg = respData is Map
            ? (respData['error'] as String?) ?? 'Failed to create verification'
            : 'Failed to create verification';
        throw MinglitUserException(errorMsg);
      }

      final data = response.data as Map<String, dynamic>;
      final id = data['id'] as String;
      Log.d('createVerification success | id: $id');
      return verification.copyWith(id: id);
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] createVerification Error', e, st);
      rethrow;
    }
  }

  // Fix #308: updateVerification via EF (partner_id 변경 불가, 서버 검증)
  Future<void> updateVerification(Verification verification) async {
    Log.d('updateVerification called | id: ${verification.id}');
    try {
      final response = await supabaseClient.functions.invoke(
        'partner-manage-verification',
        body: {
          'action': 'update',
          'verification_id': verification.id,
          'category': verification.category.name,
          'internal_name': verification.internalName,
          'display_name': verification.displayName,
          'description': verification.description,
          'icon_key': verification.iconKey,
          'form_schema': verification.formSchema
              .map((f) => f.toJson())
              .toList(),
          'is_active': verification.isActive,
        },
      );

      if (response.status != 200) {
        final respData = response.data;
        final errorMsg = respData is Map
            ? (respData['error'] as String?) ?? 'Failed to update verification'
            : 'Failed to update verification';
        throw MinglitUserException(errorMsg);
      }
      Log.d('updateVerification success');
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] updateVerification Error', e, st);
      rethrow;
    }
  }

  // Fix #308: deleteVerification via EF (soft delete)
  Future<void> deleteVerification(String verificationId) async {
    Log.d('deleteVerification called | verificationId: $verificationId');
    try {
      final response = await supabaseClient.functions.invoke(
        'partner-manage-verification',
        body: {
          'action': 'update',
          'verification_id': verificationId,
          'is_active': false,
        },
      );

      if (response.status != 200) {
        final respData = response.data;
        final errorMsg = respData is Map
            ? (respData['error'] as String?) ?? 'Failed to delete verification'
            : 'Failed to delete verification';
        throw MinglitUserException(errorMsg);
      }
      Log.d('deleteVerification success');
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] deleteVerification Error', e, st);
      rethrow;
    }
  }

  // Fix #308: restoreVerification via EF (is_active = true)
  Future<void> restoreVerification(String verificationId) async {
    Log.d('restoreVerification called | verificationId: $verificationId');
    try {
      final response = await supabaseClient.functions.invoke(
        'partner-manage-verification',
        body: {
          'action': 'update',
          'verification_id': verificationId,
          'is_active': true,
        },
      );

      if (response.status != 200) {
        final respData = response.data;
        final errorMsg = respData is Map
            ? (respData['error'] as String?) ?? 'Failed to restore verification'
            : 'Failed to restore verification';
        throw MinglitUserException(errorMsg);
      }
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

  // Fix #309: reviewRequest via partner-review-submission EF
  Future<void> reviewRequest({
    required String submissionId,
    required VerificationStatus status,
    String? comment,
  }) async {
    Log.d(
      'reviewRequest called | submissionId: $submissionId, status: $status',
    );
    try {
      final response = await supabaseClient.functions.invoke(
        'partner-review-submission',
        body: {
          'action': 'review',
          'submission_id': submissionId,
          'result': status.name,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
        },
      );

      if (response.status != 200) {
        final respData = response.data;
        final errorMsg = respData is Map
            ? (respData['error'] as String?) ?? 'Failed to review submission'
            : 'Failed to review submission';
        throw MinglitUserException(errorMsg);
      }
      Log.d('reviewRequest success');
    } catch (e, st) {
      Log.e('❌ [VerificationRepo] reviewRequest Error', e, st);
      rethrow;
    }
  }

  // Fix #309: submitComment — partner uses partner-review-submission EF,
  // user uses user-submit-verification EF
  Future<void> submitComment({
    required String submissionId,
    required Map<String, dynamic> content,
    bool isPartner = false,
  }) async {
    Log.d('submitComment called | submissionId: $submissionId');
    try {
      final text = content['text'] as String? ?? '';
      final efName = isPartner
          ? 'partner-review-submission'
          : 'user-submit-verification';
      final response = await supabaseClient.functions.invoke(
        efName,
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
