part of 'tag_repository.dart';

mixin _TagRepositoryCommands on _SupabaseTagContext {
  /// Upserts the current user's interest tags via RPC.
  ///
  /// Replaces the existing interest tag list with [tagIds].
  Future<void> upsertUserInterestTags(List<String> tagIds) async {
    try {
      await supabaseClient.rpc<dynamic>(
        'upsert_user_interest_tags',
        params: {'p_tag_ids': tagIds},
      );
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  }
}
