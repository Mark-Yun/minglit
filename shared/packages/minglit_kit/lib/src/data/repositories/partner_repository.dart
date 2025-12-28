import 'package:image_picker/image_picker.dart' show XFile;
import 'package:minglit_kit/src/data/models/partner_application.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'partner_repository.g.dart';

/// Provider for PartnerRepository.
@Riverpod(keepAlive: true)
PartnerRepository partnerRepository(Ref ref) {
  return PartnerRepository();
}

/// Repository for managing Partner-related data.
///
/// Handles database interactions for:
/// - Partner Application (Submit, List, Review).
/// - Member Management (List members, Update roles).
/// - File Uploads (Proof documents).
class PartnerRepository {
  /// Creates a [PartnerRepository] with a [SupabaseClient].
  PartnerRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// **Submit Application**
  ///
  /// Uploads proof files to Storage and inserts a record into `partner_applications`.
  /// Uses a transaction-like flow (manual rollback on error) to ensure data consistency.
  Future<void> submitApplication({
    required Map<String, dynamic> applicationData,
    required XFile bizRegistrationFile,
    required XFile bankbookFile,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw const AuthException('User not authenticated');

    Log.d('🚀 [PartnerRepo] Submitting Application for user: $userId');

    String? bizRegPath;
    String? bankbookPath;

    try {
      bizRegPath = await _uploadFile(userId, bizRegistrationFile, 'biz_reg');
      bankbookPath = await _uploadFile(userId, bankbookFile, 'bankbook');

      await _supabase.from('partner_applications').insert({
        'user_id': userId,
        ...applicationData,
        'biz_registration_path': bizRegPath,
        'bankbook_path': bankbookPath,
        'status': 'pending',
      });

      Log.i('🎉 [PartnerRepo] Application submitted successfully!');
    } on Exception catch (e, stackTrace) {
      Log.e('❌ [PartnerRepo] Application Failed', e, stackTrace);
      if (bizRegPath != null || bankbookPath != null) {
        await _supabase.storage.from('partner-proofs').remove([
          if (bizRegPath != null) bizRegPath,
          if (bankbookPath != null) bankbookPath,
        ]);
      }
      rethrow;
    }
  }

  Future<String> _uploadFile(String userId, XFile file, String type) async {
    final extension = p.extension(file.name);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$userId/${type}_$timestamp$extension';
    final bytes = await file.readAsBytes();

    await _supabase.storage
        .from('partner-proofs')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: file.mimeType),
        );
    return path;
  }

  /// Fetches the most recent application for the current user.
  Future<PartnerApplication?> getMyApplication() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final data =
        await _supabase
            .from('partner_applications')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

    if (data == null) return null;
    return PartnerApplication.fromJson(data);
  }

  /// Fetches all applications (Admin functionality).
  Future<List<PartnerApplication>> getAllApplications({
    String? status,
    String? searchTerm,
  }) async {
    var query = _supabase.from('partner_applications').select();

    if (status != null && status != 'all') {
      query = query.eq('status', status);
    }

    if (searchTerm != null && searchTerm.isNotEmpty) {
      query = query.or(
        'brand_name.ilike.%$searchTerm%,biz_name.ilike.%$searchTerm%',
      );
    }

    final data =
        await query.order('created_at', ascending: false) as List<dynamic>;

    return data
        .map(
          (dynamic json) =>
              PartnerApplication.fromJson(json as Map<String, dynamic>),
        )
        .toList();
  }

  /// Reviews an application (Admin functionality).
  Future<void> reviewApplication({
    required String applicationId,
    required String status,
    String? adminComment,
  }) async {
    Log.d('⚖️ [PartnerRepo] Reviewing Application: ID=$applicationId');
    await _supabase
        .from('partner_applications')
        .update({
          'status': status,
          'admin_comment': adminComment,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', applicationId);
  }

  /// Fetches members belonging to a specific partner.
  Future<List<Map<String, dynamic>>> getPartnerMembers(String partnerId) async {
    final data = await _supabase
        .from('partner_member_permissions')
        .select('*, user:user_profiles(*)')
        .eq('partner_id', partnerId)
        .order('joined_at', ascending: true);
    return (data as List<dynamic>).cast<Map<String, dynamic>>();
  }

  /// Updates a member's role.
  Future<void> updateMemberRole({
    required String partnerId,
    required String userId,
    required String role,
  }) async {
    Log.d('🎭 [PartnerRepo] Updating Role: Partner=$partnerId, User=$userId');
    await _supabase
        .from('partner_member_permissions')
        .update({'role': role})
        .match(
          {'partner_id': partnerId, 'user_id': userId},
        );
  }

  /// Updates a member's specific permissions.
  Future<void> updateMemberPermissions({
    required String partnerId,
    required String userId,
    required List<String> permissions,
  }) async {
    Log.d('⚙️ [PartnerRepo] Updating Permissions: Partner=$partnerId');
    await _supabase
        .from('partner_member_permissions')
        .update({'permissions': permissions})
        .match(
          {'partner_id': partnerId, 'user_id': userId},
        );
  }
}
