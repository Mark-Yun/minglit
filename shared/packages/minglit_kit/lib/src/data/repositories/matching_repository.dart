import 'package:minglit_kit/src/data/models/matching.dart';
import 'package:minglit_kit/src/data/models/user_profile.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'matching_repository.g.dart';

/// Provides the [MatchingRepository].
@Riverpod(keepAlive: true)
MatchingRepository matchingRepository(Ref ref) {
  return MatchingRepository();
}

/// Repository for matching rules and votes.
class MatchingRepository {
  /// Creates a [MatchingRepository] with a Supabase client.
  MatchingRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Fetches matching rules for a specific event.
  Future<List<MatchRule>> getMatchRules(String eventId) async {
    try {
      final data =
          await _supabase.from('match_rules').select().eq('event_id', eventId)
              as List;
      return data.map((e) {
        return MatchRule.fromJson(e as Map<String, dynamic>);
      }).toList();
    } catch (e, st) {
      Log.e('❌ [MatchingRepo] getMatchRules Error', e, st);
      rethrow;
    }
  }

  /// Updates matching rules for an event via partner-manage-match EF.
  /// Replaces all existing rules with the new list.
  // Fix #305: RLS write → EF 전환 + vote_count 지원
  Future<void> updateMatchRules({
    required String eventId,
    required List<Map<String, dynamic>> rules,
  }) async {
    try {
      await _supabase.functions.invoke(
        'partner-manage-match',
        body: {
          'action': 'set_rules',
          'event_id': eventId,
          'rules': rules.map((r) {
            final rule = <String, dynamic>{
              'source_group_id': r['source_group_id'],
              'target_group_id': r['target_group_id'],
            };
            if (r['vote_count'] != null) {
              rule['vote_count'] = r['vote_count'];
            }
            return rule;
          }).toList(),
        },
      );
      Log.d('updateMatchRules success | count: ${rules.length}');
    } catch (e, st) {
      Log.e('❌ [MatchingRepo] updateMatchRules Error', e, st);
      rethrow;
    }
  }

  /// Clears all matching rules for an event via partner-manage-match EF.
  // Fix #305: RLS write → EF 전환
  Future<void> clearMatchRules({required String eventId}) async {
    try {
      await _supabase.functions.invoke(
        'partner-manage-match',
        body: {
          'action': 'clear_rules',
          'event_id': eventId,
        },
      );
      Log.d('clearMatchRules success | eventId: $eventId');
    } catch (e, st) {
      Log.e('❌ [MatchingRepo] clearMatchRules Error', e, st);
      rethrow;
    }
  }

  /// Casts a vote for a candidate via user-cast-vote EF.
  // Fix #306: RLS write → EF 전환 (direct match_votes INSERT → user-cast-vote EF)
  Future<void> castVote({
    required String eventId,
    required String candidateId,
  }) async {
    try {
      await _supabase.functions.invoke(
        'user-cast-vote',
        body: {
          'event_id': eventId,
          'candidate_id': candidateId,
        },
      );
      Log.d('castVote success | candidate: $candidateId');
    } catch (e, st) {
      Log.e('❌ [MatchingRepo] castVote Error', e, st);
      rethrow;
    }
  }

  /// Fetches successful matches for the current user in an event.
  /// Also fetches basic profile info and secure contact info.
  Future<List<MatchPair>> getMyMatches(String eventId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // 1. Fetch from View
      final data =
          await _supabase
                  .from('my_matches_view')
                  .select()
                  .eq('event_id', eventId)
              as List;
      final matches = data.map((e) {
        return MatchPair.fromJson(e as Map<String, dynamic>);
      }).toList();

      if (matches.isEmpty) return [];

      // 2. Enrich with Partner Profile & Contact via get_matched_user_info RPC
      final enrichedMatches = await Future.wait(
        matches.map((m) async {
          final info =
              await _supabase.rpc<List<dynamic>>(
                    'get_matched_user_info',
                    params: {
                      'p_target_user_id': m.partnerId,
                      'p_target_event_id': eventId,
                    },
                  )
                  as List?;
          final userData = (info?.isNotEmpty ?? false)
              ? info!.first as Map<String, dynamic>
              : null;
          return m.copyWith(
            partnerName: userData?['user_name'] as String?,
            partnerProfileImage: userData?['profile_image_url'] as String?,
            partnerContact: userData?['phone_number'] as String?,
          );
        }),
      );

      return enrichedMatches;
    } catch (e, st) {
      Log.e('❌ [MatchingRepo] getMyMatches Error', e, st);
      rethrow;
    }
  }

  /// Fetches the voter's current vote count for an event.
  // Fix #306: 잔여 투표 수 표시용
  Future<int> getMyVoteCount(String eventId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    try {
      final data = await _supabase
          .from('match_votes')
          .select()
          .eq('event_id', eventId)
          .eq('voter_id', userId) as List;
      return data.length;
    } catch (e, st) {
      Log.e('❌ [MatchingRepo] getMyVoteCount Error', e, st);
      rethrow;
    }
  }

  /// Fetches the voted candidate IDs for the current user in an event.
  // Fix #306: 투표 완료된 후보 비활성화용
  Future<Set<String>> getMyVotedCandidateIds(String eventId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return {};

    try {
      final data = await _supabase
          .from('match_votes')
          .select('candidate_id')
          .eq('event_id', eventId)
          .eq('voter_id', userId) as List;
      return data
          .map((e) => (e as Map<String, dynamic>)['candidate_id'] as String)
          .toSet();
    } catch (e, st) {
      Log.e('❌ [MatchingRepo] getMyVotedCandidateIds Error', e, st);
      rethrow;
    }
  }

  /// Fetches candidates that the current user can vote for.
  /// Logic:
  /// 1. Find which group the current user belongs to in this event
  ///    (via Ticket).
  /// 2. Find target groups allowed by MatchRules.
  /// 3. Fetch participants belonging to those target groups.
  Future<List<UserProfile>> getMatchingCandidates(String eventId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // 1. 내 티켓의 타겟 그룹 확인
      // 2. 매칭 룰이 있으면 타겟 그룹으로 필터링
      // 3. 룰이 없으면 성별 반대 그룹으로 필터링

      final myParticipant = await _supabase
          .from('event_participants')
          .select('ticket:ticket_id(target_entry_group_ids)')
          .eq('event_id', eventId)
          .eq('user_id', userId)
          .maybeSingle();

      if (myParticipant == null) return [];

      final ticketData = myParticipant['ticket'] as Map<String, dynamic>;
      final targetEntryGroupIds = ticketData['target_entry_group_ids'];
      if (targetEntryGroupIds == null) return [];
      final myGroupIds = List<String>.from(targetEntryGroupIds as List);
      if (myGroupIds.isEmpty) return [];

      final rules =
          await _supabase
                  .from('match_rules')
                  .select('target_group_id')
                  .eq('event_id', eventId)
                  .inFilter('source_group_id', myGroupIds)
              as List;
      final targetGroupIds = rules
          .map((rule) {
            return (rule as Map<String, dynamic>)['target_group_id'] as String?;
          })
          .whereType<String>()
          .toSet()
          .toList();

      if (targetGroupIds.isEmpty) {
        final myGroups =
            await _supabase
                    .from('entry_groups')
                    .select('id, gender')
                    .inFilter('id', myGroupIds)
                as List;
        final myGender = myGroups
            .map((group) {
              return (group as Map<String, dynamic>)['gender'] as String?;
            })
            .firstWhere((gender) => gender != null, orElse: () => null);

        if (myGender != null) {
          final oppositeGroups =
              await _supabase
                      .from('entry_groups')
                      .select('id')
                      .eq('event_id', eventId)
                      .neq('gender', myGender)
                  as List;
          targetGroupIds.addAll(
            oppositeGroups.map((group) {
              return (group as Map<String, dynamic>)['id'] as String?;
            }).whereType<String>(),
          );
        }
      }

      if (targetGroupIds.isEmpty) return [];

      final participants =
          await _supabase
                  .from('event_participants')
                  .select(
                    'user_id, display_name, birth_year, '
                    'ticket:ticket_id(target_entry_group_ids)',
                  )
                  .eq('event_id', eventId)
                  .neq('user_id', userId)
                  .filter('ticket.target_entry_group_ids', 'ov', targetGroupIds)
              as List;
      final candidates = participants.map((p) {
        final pMap = p as Map<String, dynamic>;
        // Build minimal UserProfile from event_participants blurred data
        return UserProfile(
          id: pMap['user_id'] as String,
          name: (pMap['display_name'] as String?) ?? '',
          username: '',
          birthYear: pMap['birth_year'] as int?,
        );
      }).toList();

      return candidates;
    } catch (e, st) {
      Log.e('❌ [MatchingRepo] getMatchingCandidates Error', e, st);
      rethrow;
    }
  }
}
