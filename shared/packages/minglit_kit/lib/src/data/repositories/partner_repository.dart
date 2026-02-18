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
    Log.d('getPartners called');
    try {
      final data =
          await _supabase
                  .from('partners')
                  .select()
                  .eq('is_active', true)
                  .order('created_at', ascending: false)
              as List;
      final result = data.map((json) {
        return Partner.fromJson(json as Map<String, dynamic>);
      }).toList();

      Log.d('getPartners success | count: ${result.length}');
      return result;
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] getPartners Error', e, st);
      rethrow;
    }
  }

  /// Fetches partners managed by the current user.
  Future<List<Partner>> getMyManagedPartners() async {
    final userId = _supabase.auth.currentUser?.id;
    Log.d('getMyManagedPartners called | user: $userId');

    if (userId == null) {
      Log.w('⚠️ [PartnerRepo] User not logged in');
      return [];
    }

    // 1. Get partner_ids from permissions
    try {
      final permissions =
          await _supabase
                  .from('partner_member_permissions')
                  .select('partner_id')
                  .eq('user_id', userId)
              as List;

      Log.d('🔍 [PartnerRepo] Found permissions raw data: $permissions');
      final partnerIds = permissions
          .map((e) {
            return (e as Map<String, dynamic>)['partner_id'] as String?;
          })
          .whereType<String>()
          .toList();

      if (partnerIds.isEmpty) {
        Log.w('⚠️ [PartnerRepo] No managed partners found for user');
        return [];
      }

      // 2. Get partners details
      final data =
          await _supabase
                  .from('partners')
                  .select()
                  .inFilter('id', partnerIds)
                  .eq('is_active', true)
              as List;
      final result = data.map((json) {
        return Partner.fromJson(json as Map<String, dynamic>);
      }).toList();
      Log.d('getMyManagedPartners success | count: ${result.length}');
      return result;
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

    Log.d('submitApplication called | user: $userId');

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

      Log.i('submitApplication success');
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
    Log.d('_uploadFile called | type: $type, file: ${file.name}');
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
    Log.d('_uploadFile success | path: $path');
    return path;
  }

  /// Fetches the most recent application for the current user.
  Future<PartnerApplication?> getMyApplication() async {
    Log.d('getMyApplication called');
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      Log.d('getMyApplication: User not logged in');
      return null;
    }

    try {
      final data = await _supabase
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
      var query = _supabase.from('partner_applications').select();

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
      await _supabase
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

  /// Fetches members belonging to a specific partner.
  Future<List<Map<String, dynamic>>> getPartnerMembers(String partnerId) async {
    Log.d('getPartnerMembers called | partnerId: $partnerId');
    try {
      final data =
          await _supabase
                  .from('partner_member_permissions')
                  .select('*, user:user_profiles(*)')
                  .eq('partner_id', partnerId)
                  .order('joined_at', ascending: true)
              as List;
      final result = data.map((entry) {
        return entry as Map<String, dynamic>;
      }).toList();
      Log.d('getPartnerMembers success | count: ${result.length}');
      return result;
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
    Log.d(
      'updateMemberRole called | partnerId: $partnerId, userId: $userId,'
      ' role: $role',
    );
    try {
      await _supabase
          .from('partner_member_permissions')
          .update({'role': role})
          .match(
            {'partner_id': partnerId, 'user_id': userId},
          );
      Log.d('updateMemberRole success');
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
    Log.d(
      'updateMemberPermissions called | partnerId: $partnerId, userId: $userId,'
      ' perms: $permissions',
    );
    try {
      await _supabase
          .from('partner_member_permissions')
          .update({'permissions': permissions})
          .match(
            {'partner_id': partnerId, 'user_id': userId},
          );
      Log.d('updateMemberPermissions success');
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] updateMemberPermissions Error', e, st);
      rethrow;
    }
  }

  /// Generates a signed URL for a file in the partner-proofs bucket.
  Future<String> getSignedUrl(String path) async {
    Log.d('getSignedUrl called | path: $path');
    try {
      // Create a signed URL valid for 10 minutes (600 seconds)
      final signedUrl = await _supabase.storage
          .from('partner-proofs')
          .createSignedUrl(path, 600);
      return signedUrl;
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] getSignedUrl Error', e, st);
      rethrow;
    }
  }

  /// Fetches a specific partner by ID.
  Future<Partner?> getPartnerById(String partnerId) async {
    Log.d('getPartnerById called | partnerId: $partnerId');
    try {
      final data = await _supabase
          .from('partners')
          .select()
          .eq('id', partnerId)
          .maybeSingle();

      if (data == null) {
        Log.d('getPartnerById success | result: null');
        return null;
      }
      final result = Partner.fromJson(data);
      Log.d('getPartnerById success | name: ${result.name}');
      return result;
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] getPartnerById Error', e, st);
      rethrow;
    }
  }

  /// Fetches the current user's role and permissions for a specific partner.
  Future<Map<String, dynamic>?> getMyMemberRole(String partnerId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final data = await _supabase
          .from('partner_member_permissions')
          .select('role, permissions')
          .match({'partner_id': partnerId, 'user_id': userId})
          .maybeSingle();

      return data;
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] getMyMemberRole Error', e, st);
      rethrow;
    }
  }

  /// Fetches aggregated revenue stats for a partner.
  Future<Map<String, dynamic>> getPartnerRevenueStats(String partnerId) async {
    Log.d('getPartnerRevenueStats called | partnerId: $partnerId');
    try {
      final data = await _supabase
          .from('partner_revenue_stats')
          .select()
          .eq('partner_id', partnerId)
          .maybeSingle();

      if (data == null) {
        return {
          'partner_id': partnerId,
          'total_sales': 0,
          'total_refunds': 0,
          'net_amount': 0,
        };
      }
      return data;
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] getPartnerRevenueStats Error', e, st);
      rethrow;
    }
  }

  /// Fetches monthly revenue stats for charting.
  Future<List<Map<String, dynamic>>> getPartnerMonthlyRevenue(
    String partnerId,
  ) async {
    Log.d('getPartnerMonthlyRevenue called | partnerId: $partnerId');
    try {
      final data =
          await _supabase
                  .from('partner_monthly_revenue')
                  .select()
                  .eq('partner_id', partnerId)
                  .order('month', ascending: true)
              as List;
      return data.map((entry) {
        return entry as Map<String, dynamic>;
      }).toList();
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] getPartnerMonthlyRevenue Error', e, st);
      rethrow;
    }
  }

  /// Fetches settlement records for a partner.
  Future<List<Map<String, dynamic>>> getPartnerSettlements(
    String partnerId,
  ) async {
    Log.d('getPartnerSettlements called | partnerId: $partnerId');
    try {
      final data =
          await _supabase
                  .from('settlements')
                  .select()
                  .eq('partner_id', partnerId)
                  .order('event_date', ascending: false)
              as List;
      return data.map((entry) {
        return entry as Map<String, dynamic>;
      }).toList();
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] getPartnerSettlements Error', e, st);
      rethrow;
    }
  }
}
