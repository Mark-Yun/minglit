import 'package:minglit_kit/src/data/models/user_profile.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'user_repository.g.dart';

/// Provides the [UserRepository].
@Riverpod(keepAlive: true)
UserRepository userRepository(Ref ref) {
  return SupabaseUserRepository();
}

/// Repository interface for user profile data.
abstract class UserRepository {
  /// Fetches the user profile for the given [userId].
  Future<UserProfile?> getUserProfile(String userId);

  /// Fetches approved verification IDs for the given [userId].
  Future<List<String>> getApprovedVerificationIds(String userId);
}

/// Supabase-backed implementation of [UserRepository].
class SupabaseUserRepository implements UserRepository {
  /// Creates a [SupabaseUserRepository] with an optional Supabase client.
  SupabaseUserRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  @override
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final data = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();
      return UserProfile.fromJson(data);
    } on PostgrestException catch (e, st) {
      // Fix #1952: PGRST116 = no rows — valid "not found" case.
      if (e.code == 'PGRST116') return null;
      Log.e('❌ [UserRepo] getUserProfile Error', e, st);
      rethrow;
    } catch (e, st) {
      Log.e('❌ [UserRepo] getUserProfile Error', e, st);
      rethrow;
    }
  }

  @override
  Future<List<String>> getApprovedVerificationIds(String userId) async {
    try {
      final data = await _supabase
          .from('partner_verified_users')
          .select('verification_id')
          .eq('user_id', userId);
      return (data as List)
          .map(
            (dynamic e) =>
                (e as Map<String, dynamic>)['verification_id'] as String?,
          )
          .whereType<String>()
          .toList();
    } catch (e, st) {
      // Fix #1952: rethrow instead of silently returning [].
      Log.e('❌ [UserRepo] getApprovedVerificationIds Error', e, st);
      rethrow;
    }
  }
}
