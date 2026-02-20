part of 'partner_repository.dart';

mixin _PartnerApplicationRepository on _SupabasePartnerContext {
  /// **Submit Application**
  ///
  /// Uploads proof files to Storage and inserts a record into
  /// `partner_applications`.
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

      await supabaseClient.from('partner_applications').insert({
        'user_id': userId,
        ...applicationData,
        'biz_registration_path': bizRegPath,
        'bankbook_path': bankbookPath,
        'status': 'pending',
      });

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
}
