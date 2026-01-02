import 'package:image_picker/image_picker.dart' show XFile;
import 'package:minglit_kit/src/data/models/partner.dart';
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

  /// Fetches all active partners.
  Future<List<Partner>> getPartners() async {
    try {
      final data = await _supabase
          .from('partners')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (data as List<dynamic>)
          .map((json) => Partner.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] getPartners Error', e, st);
      rethrow;
    }
  }

  /// Fetches partners managed by the current user.
  Future<List<Partner>> getMyManagedPartners() async {
    final userId = _supabase.auth.currentUser?.id;
    Log.d('🔍 [PartnerRepo] getMyManagedPartners for user: $userId');

    if (userId == null) {
      Log.w('⚠️ [PartnerRepo] User not logged in');
      return [];
    }

    // 1. Get partner_ids from permissions
    try {
      final permissions = await _supabase
          .from('partner_member_permissions')
          .select('partner_id')
          .eq('user_id', userId);

      Log.d('🔍 [PartnerRepo] Found permissions raw data: $permissions');

      final partnerIds = permissions
          .map((e) => e['partner_id'] as String)
          .toList();

      if (partnerIds.isEmpty) {
        Log.w('⚠️ [PartnerRepo] No managed partners found for user');
        return [];
      }

      // 2. Get partners details
      final data = await _supabase
          .from('partners')
          .select()
          .inFilter('id', partnerIds)
          .eq('is_active', true);

      Log.d('🔍 [PartnerRepo] Fetched partners raw data: $data');

      return data.map(Partner.fromJson).toList();
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] getMyManagedPartners Error', e, st);
      rethrow;
    }
  }

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
      // Attempt cleanup (Best effort)
      try {
        await _supabase.storage
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

    try {
      final data = await _supabase
          .from('partner_applications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) return null;
      return PartnerApplication.fromJson(data);
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
    try {
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
    Log.d('⚖️ [PartnerRepo] Reviewing Application: ID=$applicationId');
    try {
      await _supabase
          .from('partner_applications')
          .update({
            'status': status,
            'admin_comment': adminComment,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', applicationId);
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] reviewApplication Error', e, st);
      rethrow;
    }
  }

  /// Fetches members belonging to a specific partner.
  Future<List<Map<String, dynamic>>> getPartnerMembers(String partnerId) async {
    try {
      final data = await _supabase
          .from('partner_member_permissions')
          .select('*, user:user_profiles(*)')
          .eq('partner_id', partnerId)
          .order('joined_at', ascending: true);
      return (data as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] getPartnerMembers Error', e, st);
      rethrow;
    }
  }

  /// Updates a member's role.
  Future<void> updateMemberRole({
    required String partnerId,
    required String userId,
    required String role,
  }) async {
    Log.d('🎭 [PartnerRepo] Updating Role: Partner=$partnerId, User=$userId');
    try {
      await _supabase
          .from('partner_member_permissions')
          .update({'role': role})
          .match(
            {'partner_id': partnerId, 'user_id': userId},
          );
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] updateMemberRole Error', e, st);
      rethrow;
    }
  }

  /// Updates a member's specific permissions.
  Future<void> updateMemberPermissions({
    required String partnerId,
    required String userId,
    required List<String> permissions,
  }) async {
    Log.d('⚙️ [PartnerRepo] Updating Permissions: Partner=$partnerId');
    try {
      await _supabase
          .from('partner_member_permissions')
          .update({'permissions': permissions})
          .match(
            {'partner_id': partnerId, 'user_id': userId},
          );
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] updateMemberPermissions Error', e, st);
      rethrow;
    }
  }

  /// Fetches a specific partner by ID.
  Future<Partner?> getPartnerById(String partnerId) async {
    try {
      final data = await _supabase
          .from('partners')
          .select()
          .eq('id', partnerId)
          .maybeSingle();

      if (data == null) return null;
      return Partner.fromJson(data);
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] getPartnerById Error', e, st);
      rethrow;
    }
  }
}
