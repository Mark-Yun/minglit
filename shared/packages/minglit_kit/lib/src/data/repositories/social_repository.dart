import 'package:minglit_kit/src/data/models/social_interaction.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'social_repository.g.dart';

/// Provider for SocialRepository.
@Riverpod(keepAlive: true)
SocialRepository socialRepository(Ref ref) {
  return SocialRepository();
}

/// Repository for handling social interactions (Like, Subscribe, Bookmark).
class SocialRepository {
  SocialRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Toggles an interaction for the current user.
  /// If it exists, it will be deleted. If not, it will be created.
  Future<bool> toggleInteraction({
    required String targetId,
    required SocialTargetType targetType,
    required SocialInteractionType interactionType,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    Log.d('toggleInteraction | targetId: $targetId');
    Log.d('toggleInteraction | type: $interactionType');

    try {
      // 1. Check if interaction already exists
      final existing = await _supabase
          .from('social_interactions')
          .select()
          .eq('user_id', userId)
          .eq('target_id', targetId)
          .eq('interaction_type', interactionType.name)
          .maybeSingle();

      if (existing != null) {
        // 2. Delete if exists
        await _supabase
            .from('social_interactions')
            .delete()
            .eq('user_id', userId)
            .eq('target_id', targetId)
            .eq('interaction_type', interactionType.name);
        Log.d('toggleInteraction: removed');
        return false; // Now inactive
      } else {
        // 3. Insert if not exists
        await _supabase.from('social_interactions').insert({
          'user_id': userId,
          'target_id': targetId,
          'target_type': targetType.name,
          'interaction_type': interactionType.name,
        });
        Log.d('toggleInteraction: added');
        return true; // Now active
      }
    } on Object catch (e, st) {
      Log.e('❌ [SocialRepo] toggleInteraction Error', e, st);
      rethrow;
    }
  }

  /// Checks if the current user has a specific interaction with a target.
  Future<bool> getInteractionState({
    required String targetId,
    required SocialInteractionType interactionType,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final existing = await _supabase
          .from('social_interactions')
          .select()
          .eq('user_id', userId)
          .eq('target_id', targetId)
          .eq('interaction_type', interactionType.name)
          .maybeSingle();

      return existing != null;
    } on Object catch (e, st) {
      Log.e('❌ [SocialRepo] getInteractionState Error', e, st);
      return false;
    }
  }

  /// Gets the total count of a specific interaction type for a target.
  Future<int> getInteractionCount({
    required String targetId,
    required SocialInteractionType interactionType,
  }) async {
    try {
      final response = await _supabase
          .from('social_interactions')
          .select('user_id')
          .eq('target_id', targetId)
          .eq('interaction_type', interactionType.name)
          .count(CountOption.exact);

      return response.count;
    } on Object catch (e, st) {
      Log.e('❌ [SocialRepo] getInteractionCount Error', e, st);
      return 0;
    }
  }
}
