part of 'tag_repository.dart';

mixin _TagRepositoryQueries on _SupabaseTagContext {
  /// Fetches featured tags via RPC.
  Future<List<Tag>> getFeaturedTags() async {
    try {
      final data =
          await supabaseClient.rpc<dynamic>(
                'get_featured_tags',
              )
              as List;
      return data
          .map((json) => Tag.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Fetches trending tags over the given [days] window via RPC.
  Future<List<Tag>> getTrendingTags({int limit = 10, int days = 7}) async {
    try {
      final data =
          await supabaseClient.rpc<dynamic>(
                'get_trending_tags',
                params: {'p_limit': limit, 'p_days': days},
              )
              as List;
      return data
          .map((json) => Tag.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Fetches events associated with a specific [tagId] via RPC.
  Future<List<Event>> getPartiesByTag(
    String tagId, {
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final data =
          await supabaseClient.rpc<dynamic>(
                'get_parties_by_tag',
                params: {
                  'p_tag_id': tagId,
                  'p_limit': limit,
                  'p_offset': offset,
                },
              )
              as List;
      return data
          .map((json) => Event.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Fetches personalized event recommendations based on user interest tags.
  Future<List<Event>> getTagRecommendations({int limit = 10}) async {
    try {
      final data =
          await supabaseClient.rpc<dynamic>(
                'get_tag_recommendations',
                params: {'p_limit': limit},
              )
              as List;
      return data
          .map((json) => Event.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Fetches the current user's interest tags from user_interest_tags table.
  Future<List<Tag>> getUserInterestTags() async {
    try {
      final data =
          await supabaseClient
                  .from('user_interest_tags')
                  .select('tag_id, tags(*)')
                  .eq('user_id', supabaseClient.auth.currentUser!.id)
              as List;
      return data
          .map(
            (row) => Tag.fromJson(
              (row as Map<String, dynamic>)['tags'] as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Searches tags matching [query] via RPC.
  Future<List<Tag>> searchTags(String query) async {
    try {
      final data =
          await supabaseClient.rpc<dynamic>(
                'search_tags',
                params: {'p_query': query},
              )
              as List;
      return data
          .map((json) => Tag.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Fetches tags associated with a specific [partyId] via party_tags join.
  ///
  /// 편집 모드에서 기존 파티의 태그를 불러올 때 사용한다.
  Future<List<Tag>> getTagsByPartyId(String partyId) async {
    try {
      final data =
          await supabaseClient
                  .from('party_tags')
                  .select('tags(*)')
                  .eq('party_id', partyId)
              as List;
      return data
          .map(
            (row) => Tag.fromJson(
              (row as Map<String, dynamic>)['tags'] as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  }

  /// Fetches tags by a list of [tagIds].
  ///
  /// wizard state의 tagIds로 Tag 객체를 복원할 때 사용한다.
  Future<List<Tag>> getTagsByIds(List<String> tagIds) async {
    if (tagIds.isEmpty) return const [];
    try {
      final data =
          await supabaseClient.from('tags').select().inFilter('id', tagIds)
              as List;
      return data
          .map((json) => Tag.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      Error.throwWithStackTrace(e, st);
    }
  }
}
