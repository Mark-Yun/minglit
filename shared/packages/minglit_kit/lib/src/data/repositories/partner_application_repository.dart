part of 'partner_repository.dart';

mixin _PartnerApplicationRepository on _SupabasePartnerContext {
  // Fix #311: submitApplication via EF (서버 사이드 검증)
  /// **Submit Application**
  ///
  /// Uploads proof files to Storage, saves a draft via EF, then submits.
  /// Uses a transaction-like flow (manual rollback on error) to ensure
  /// data consistency.
  Future<void> submitApplication({
    required Map<String, dynamic> applicationData,
    required XFile bizRegistrationFile,
    required XFile bankbookFile,
  }) async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) throw const AuthException('User not authenticated');

    Log.d('submitApplication called | user: $userId');

    String? bizRegPath;
    String? bankbookPath;

    try {
      bizRegPath = await _uploadFile(userId, bizRegistrationFile, 'biz_reg');
      bankbookPath = await _uploadFile(userId, bankbookFile, 'bankbook');

      // Fix #311: save_draft via EF → submit via EF
      final draftResponse = await supabaseClient.functions.invoke(
        'partner-register',
        body: {
          'action': 'save_draft',
          'data': {
            ...applicationData,
            'biz_registration_path': bizRegPath,
            'bankbook_path': bankbookPath,
          },
        },
      );

      if (draftResponse.status != 200) {
        final respData = draftResponse.data;
        final errorMsg = respData is Map
            ? (respData['error'] as String?) ?? 'Failed to save draft'
            : 'Failed to save draft';
        throw MinglitUserException(errorMsg);
      }

      final draftData = draftResponse.data as Map<String, dynamic>;
      final applicationId = draftData['application_id'] as String;

      final submitResponse = await supabaseClient.functions.invoke(
        'partner-register',
        body: {
          'action': 'submit',
          'application_id': applicationId,
        },
      );

      if (submitResponse.status != 200) {
        final respData = submitResponse.data;
        final errorMsg = respData is Map
            ? (respData['error'] as String?) ?? 'Failed to submit application'
            : 'Failed to submit application';
        throw MinglitUserException(errorMsg);
      }

      Log.i('submitApplication success');
    } on Exception catch (e, stackTrace) {
      Log.e('❌ [PartnerRepo] Application Failed', e, stackTrace);
      // Attempt cleanup (Best effort)
      try {
        await supabaseClient.storage
            .from('partner-proofs')
            .remove(
              [bizRegPath, bankbookPath].whereType<String>().toList(),
            );
      } on Exception catch (_) {
        // Ignore cleanup errors
      }
      rethrow;
    }
  }

  Future<String> _uploadFile(String userId, XFile file, String type) async {
    Log.d('_uploadFile called | type: $type, file: ${file.name}');
    final extension = p.extension(file.name);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/${type}_$timestamp$extension';
    final bytes = await file.readAsBytes();

    await supabaseClient.storage
        .from('partner-proofs')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: file.mimeType),
        );
    Log.d('_uploadFile success | path: $path');
    return path;
  }

  /// Fetches the most recent application for the current user.
  Future<PartnerApplication?> getMyApplication() async {
    Log.d('getMyApplication called');
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      Log.d('getMyApplication: User not logged in');
      return null;
    }

    try {
      final data = await supabaseClient
          .from('partner_applications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) {
        Log.d('getMyApplication success | result: null');
        return null;
      }
      final result = PartnerApplication.fromJson(data);
      Log.d('getMyApplication success | id: ${result.id}');
      return result;
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] getMyApplication Error', e, st);
      rethrow;
    }
  }

  /// Fetches all applications (Admin functionality).
  Future<List<PartnerApplication>> getAllApplications({
    String? status,
    String? searchTerm,
  }) async {
    Log.d('getAllApplications called | status: $status, search: $searchTerm');
    try {
      var query = supabaseClient.from('partner_applications').select();

      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }

      if (searchTerm != null && searchTerm.isNotEmpty) {
        query = query.or(
          'brand_name.ilike.%$searchTerm%,biz_name.ilike.%$searchTerm%',
        );
      }

      final data = await query.order('created_at', ascending: false) as List;
      final result = data.map((json) {
        return PartnerApplication.fromJson(json as Map<String, dynamic>);
      }).toList();

      Log.d('getAllApplications success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] getAllApplications Error', e, st);
      rethrow;
    }
  }

  /// Reviews an application (Admin functionality).
  Future<void> reviewApplication({
    required String applicationId,
    required String status,
    String? adminComment,
  }) async {
    Log.d(
      '''reviewApplication called | id: $applicationId, status: $status, comment: $adminComment''',
    );
    try {
      await supabaseClient
          .from('partner_applications')
          .update({
            'status': status,
            'admin_comment': adminComment,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', applicationId);
      Log.d('reviewApplication success');
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] reviewApplication Error', e, st);
      rethrow;
    }
  }

  /// Generates a signed URL for a file in the partner-proofs bucket.
  Future<String> getSignedUrl(String path) async {
    Log.d('getSignedUrl called | path: $path');
    try {
      // Create a signed URL valid for 10 minutes (600 seconds)
      final signedUrl = await supabaseClient.storage
          .from('partner-proofs')
          .createSignedUrl(path, 600);
      return signedUrl;
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] getSignedUrl Error', e, st);
      rethrow;
    }
  }

  // Fix #311: saveDraft via EF (서버 사이드 소유권 검증)
  /// **Save Draft**
  ///
  /// Inserts a new draft if application.id is empty, otherwise updates the
  /// existing record via EF. Returns the persisted PartnerApplication with
  /// its id.
  Future<PartnerApplication> saveDraft(PartnerApplication application) async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) throw const AuthException('User not authenticated');

    Log.d('saveDraft called | user: $userId, id: ${application.id}');

    try {
      final response = await supabaseClient.functions.invoke(
        'partner-register',
        body: {
          'action': 'save_draft',
          if (application.id.isNotEmpty) 'application_id': application.id,
          'data': application.toDbJson(),
        },
      );

      if (response.status != 200) {
        final respData = response.data;
        final errorMsg = respData is Map
            ? (respData['error'] as String?) ?? 'Failed to save draft'
            : 'Failed to save draft';
        throw MinglitUserException(errorMsg);
      }

      final data = response.data as Map<String, dynamic>;
      final applicationId = data['application_id'] as String;

      // Re-fetch the full record since EF only returns the id
      final fullData = await supabaseClient
          .from('partner_applications')
          .select()
          .eq('id', applicationId)
          .single();

      final result = PartnerApplication.fromJson(fullData);
      Log.i('saveDraft success | id: ${result.id}');
      return result;
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] saveDraft Error', e, st);
      rethrow;
    }
  }

  // Fix #311: updateApplication via EF (서버 사이드 상태/소유권 검증)
  /// **Update Application**
  ///
  /// Updates an existing application by id via EF. The EF enforces that only
  /// records in status 'draft' or 'needs_correction' can be updated.
  /// Returns the updated [PartnerApplication].
  Future<PartnerApplication> updateApplication(
    PartnerApplication application,
  ) async {
    Log.d('updateApplication called | id: ${application.id}');
    try {
      final response = await supabaseClient.functions.invoke(
        'partner-register',
        body: {
          'action': 'update',
          'application_id': application.id,
          'data': application.toDbJson(),
        },
      );

      if (response.status != 200) {
        final respData = response.data;
        final errorMsg = respData is Map
            ? (respData['error'] as String?) ?? 'Failed to update application'
            : 'Failed to update application';
        throw MinglitUserException(errorMsg);
      }

      // Re-fetch the full record
      final fullData = await supabaseClient
          .from('partner_applications')
          .select()
          .eq('id', application.id)
          .single();

      final result = PartnerApplication.fromJson(fullData);
      Log.i('updateApplication success | id: ${result.id}');
      return result;
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] updateApplication Error', e, st);
      rethrow;
    }
  }

  // Fix #311: submitDraft via EF (서버 사이드 필수 필드 + 형식 검증)
  /// **Submit Draft**
  ///
  /// Transitions the application status from 'draft'/'needs_correction' to
  /// 'pending' via EF with server-side validation.
  /// Returns the updated [PartnerApplication].
  Future<PartnerApplication> submitDraft({
    required String applicationId,
  }) async {
    Log.d('submitDraft called | id: $applicationId');
    try {
      final response = await supabaseClient.functions.invoke(
        'partner-register',
        body: {
          'action': 'submit',
          'application_id': applicationId,
        },
      );

      if (response.status != 200) {
        final respData = response.data;
        final errorMsg = respData is Map
            ? (respData['error'] as String?) ?? 'Failed to submit draft'
            : 'Failed to submit draft';
        throw MinglitUserException(errorMsg);
      }

      // Re-fetch the full record
      final fullData = await supabaseClient
          .from('partner_applications')
          .select()
          .eq('id', applicationId)
          .single();

      final result = PartnerApplication.fromJson(fullData);
      Log.i('submitDraft success | id: ${result.id}');
      return result;
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] submitDraft Error', e, st);
      rethrow;
    }
  }

  /// **Upload Profile Image**
  ///
  /// Uploads a profile image for the current user to the partner-proofs
  /// storage bucket. Returns the storage path string.
  Future<String> uploadProfileImage(XFile file) async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) throw const AuthException('User not authenticated');

    Log.d('uploadProfileImage called | user: $userId, file: ${file.name}');
    try {
      final path = await _uploadFile(userId, file, 'profile');
      Log.i('uploadProfileImage success | path: $path');
      return path;
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] uploadProfileImage Error', e, st);
      rethrow;
    }
  }

  /// **Delete Uploaded File**
  ///
  /// Removes a previously uploaded file from the partner-proofs storage
  /// bucket by its [path].
  Future<void> deleteUploadedFile(String path) async {
    Log.d('deleteUploadedFile called | path: $path');
    try {
      await supabaseClient.storage.from('partner-proofs').remove([path]);
      Log.i('deleteUploadedFile success | path: $path');
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] deleteUploadedFile Error', e, st);
      rethrow;
    }
  }

  /// **Upload Biz Registration**
  ///
  /// Uploads a business registration file to the partner-proofs storage
  /// bucket. Returns the storage path string.
  Future<String> uploadBizRegistration(XFile file) async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) throw const AuthException('User not authenticated');
    Log.d('uploadBizRegistration called | file: ${file.name}');
    return _uploadFile(userId, file, 'biz_reg');
  }

  /// **Upload Bankbook**
  ///
  /// Uploads a bankbook file to the partner-proofs storage bucket.
  /// Returns the storage path string.
  Future<String> uploadBankbook(XFile file) async {
    final userId = supabaseClient.auth.currentUser?.id;
    if (userId == null) throw const AuthException('User not authenticated');
    Log.d('uploadBankbook called | file: ${file.name}');
    return _uploadFile(userId, file, 'bankbook');
  }
}
