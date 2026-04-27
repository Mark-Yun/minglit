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
  /// Creates a [SocialRepository] with a Supabase client.
  SocialRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Sets the interaction state for the current user with explicit intent.
  ///
  /// When [active] is true, the interaction is created (INSERT ON CONFLICT DO
  /// NOTHING — idempotent, never throws 23505).
  /// When [active] is false, the interaction is deleted (idempotent).
  ///
  /// Fix #1957: explicit intent eliminates TOCTOU races — callers pass the
  /// desired final state, so concurrent calls with the same intent are safe.
  /// Sets the interaction state for the current user with explicit intent.
  ///
  /// Delegates to the `set_social_interaction` Postgres function, which runs
  /// in a single transaction with an advisory lock — eliminating TOCTOU races
  /// and concurrent like/dislike cross-intent races.
  ///
  /// Fix #1957: explicit intent + atomic server-side operation.
  Future<void> setInteraction({
    required String targetId,
    required SocialTargetType targetType,
    required SocialInteractionType interactionType,
    required bool active,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    Log.d('setInteraction | targetId: $targetId, active: $active');
    Log.d('setInteraction | type: $interactionType');

    try {
      // Fix #1957: single RPC call — atomic transaction + advisory lock prevents
      // concurrent cross-intent (like vs dislike) races from both landing.
      await _supabase.rpc<dynamic>(
        'set_social_interaction',
        params: {
          'p_target_id': targetId,
          'p_target_type': targetType.name,
          'p_interaction_type': interactionType.name,
          'p_active': active,
        },
      );
    } on Object catch (e, st) {
      Log.e('❌ [SocialRepo] setInteraction Error', e, st);
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

  /// Blocks the given partner for the current user.
  Future<void> blockPartner(String partnerId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    try {
      await _supabase.from('social_interactions').upsert({
        'user_id': userId,
        'target_id': partnerId,
        'target_type': SocialTargetType.partner.name,
        'interaction_type': SocialInteractionType.block.name,
      });
    } on Object catch (e, st) {
      Log.e('blockPartner Error', e, st);
      rethrow;
    }
  }

  /// Unblocks a previously blocked partner.
  Future<void> unblockPartner(String partnerId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    try {
      await _supabase
          .from('social_interactions')
          .delete()
          .eq('user_id', userId)
          .eq('target_id', partnerId)
          .eq('interaction_type', SocialInteractionType.block.name);
    } on Object catch (e, st) {
      Log.e('unblockPartner Error', e, st);
      rethrow;
    }
  }

  /// Reports a partner with a reason and optional description.
  Future<void> reportPartner({
    required String partnerId,
    required String reason,
    String? description,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    try {
      await blockPartner(partnerId);
      await _supabase.from('social_interactions').upsert({
        'user_id': userId,
        'target_id': partnerId,
        'target_type': SocialTargetType.partner.name,
        'interaction_type': SocialInteractionType.report.name,
      });
      await _supabase.from('report_details').insert({
        'user_id': userId,
        'target_id': partnerId,
        'target_type': SocialTargetType.partner.name,
        'reason': reason,
        'description': ?description,
      });
    } on Object catch (e, st) {
      Log.e('reportPartner Error', e, st);
      rethrow;
    }
  }

  /// Returns the list of partner IDs blocked by the current user.
  Future<List<String>> getBlockedPartnerIds() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      final data = await _supabase
          .from('social_interactions')
          .select('target_id')
          .eq('user_id', userId)
          .eq('target_type', SocialTargetType.partner.name)
          .eq('interaction_type', SocialInteractionType.block.name);
      return data.map<String>((row) => row['target_id'] as String).toList();
    } on Object catch (e, st) {
      Log.e('getBlockedPartnerIds Error', e, st);
      return [];
    }
  }

  /// Returns profile data for all blocked partners.
  Future<List<Map<String, dynamic>>> getBlockedPartners() async {
    final ids = await getBlockedPartnerIds();
    if (ids.isEmpty) return [];
    try {
      final data = await _supabase
          .from('partners')
          .select('id, name, profile_image_url')
          .inFilter('id', ids);
      return data.cast<Map<String, dynamic>>();
    } on Object catch (e, st) {
      Log.e('getBlockedPartners Error', e, st);
      return [];
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
