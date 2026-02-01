import 'package:minglit_kit/src/data/models/matching.dart';
import 'package:minglit_kit/src/data/models/user_profile.dart';
import 'package:minglit_kit/src/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'matching_repository.g.dart';

@Riverpod(keepAlive: true)
MatchingRepository matchingRepository(Ref ref) {
  return MatchingRepository();
}

class MatchingRepository {
  MatchingRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Fetches matching rules for a specific event.
  Future<List<MatchRule>> getMatchRules(String eventId) async {
    try {
      final data = await _supabase
          .from('match_rules')
          .select()
          .eq('event_id', eventId);
      return (data as List)
          .map((e) => MatchRule.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      Log.e('❌ [MatchingRepo] getMatchRules Error', e, st);
      rethrow;
    }
  }

  /// Updates matching rules for an event.
  /// Replaces all existing rules with the new list.
  Future<void> updateMatchRules({
    required String eventId,
    required List<Map<String, String>> rules,
  }) async {
    try {
      // 1. Delete existing rules
      await _supabase.from('match_rules').delete().eq('event_id', eventId);

      // 2. Insert new rules
      if (rules.isNotEmpty) {
        final records = rules.map((r) {
          return {
            'event_id': eventId,
            'source_group_id': r['source_group_id'],
            'target_group_id': r['target_group_id'],
          };
        }).toList();

        await _supabase.from('match_rules').insert(records);
      }
      Log.d('updateMatchRules success | count: ${rules.length}');
    } catch (e, st) {
      Log.e('❌ [MatchingRepo] updateMatchRules Error', e, st);
      rethrow;
    }
  }

  /// Casts a vote for a candidate.
  Future<void> castVote({
    required String eventId,
    required String candidateId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    try {
      await _supabase.from('match_votes').insert({
        'event_id': eventId,
        'voter_id': userId,
        'candidate_id': candidateId,
      });
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
      final data = await _supabase
          .from('my_matches_view')
          .select()
          .eq('event_id', eventId);

      final matches = (data as List)
          .map((e) => MatchPair.fromJson(e as Map<String, dynamic>))
          .toList();

      if (matches.isEmpty) return [];

      // 2. Enrich with Partner Profile & Secure Contact
      final partnerIds = matches.map((m) => m.partnerId).toList();
      final profiles = await _supabase
          .from('user_profiles')
          .select()
          .inFilter('id', partnerIds);

      // 3. Fetch Secure Contact (One by one via RPC for security)
      // Note: This could be optimized, but security is priority.
      final enrichedMatches = await Future.wait(
        matches.map((m) async {
          final profileMap = profiles.firstWhere(
            (p) => p['id'] == m.partnerId,
            orElse: () => {},
          );

          final contact = await _supabase.rpc<String?>(
            'get_matched_user_contact',
            params: {
              'target_user_id': m.partnerId,
              'target_event_id': eventId,
            },
          );

          return m.copyWith(
            partnerName: profileMap['name'] as String?,
            partnerProfileImage: profileMap['profile_image_url'] as String?,
            partnerContact: contact,
          );
        }),
      );

      return enrichedMatches;
    } catch (e, st) {
      Log.e('❌ [MatchingRepo] getMyMatches Error', e, st);
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

      final ticketMap = myParticipant['ticket'] as Map<String, dynamic>?;
      final myGroupIds = List<String>.from(
        ticketMap?['target_entry_group_ids'] as List<dynamic>? ?? const [],
      );
      if (myGroupIds.isEmpty) return [];

      final rules = await _supabase
          .from('match_rules')
          .select('target_group_id')
          .eq('event_id', eventId)
          .inFilter('source_group_id', myGroupIds);

      final ruleList = (rules as List).cast<Map<String, dynamic>>();
      final targetGroupIds = ruleList
          .map((rule) => rule['target_group_id'] as String)
          .toSet()
          .toList();

      if (targetGroupIds.isEmpty) {
        final myGroups = await _supabase
            .from('entry_groups')
            .select('id, gender')
            .inFilter('id', myGroupIds);

        final myGender = (myGroups as List)
            .cast<Map<String, dynamic>>()
            .map((group) => group['gender'] as String?)
            .firstWhere((gender) => gender != null, orElse: () => null);

        if (myGender != null) {
          final oppositeGroups = await _supabase
              .from('entry_groups')
              .select('id')
              .eq('event_id', eventId)
              .neq('gender', myGender);

          final oppositeGroupList = (oppositeGroups as List)
              .cast<Map<String, dynamic>>();
          targetGroupIds.addAll(
            oppositeGroupList.map((group) => group['id'] as String),
          );
        }
      }

      if (targetGroupIds.isEmpty) return [];

      final participants = await _supabase
          .from('event_participants')
          .select(
            'user_id, user:user_profiles(*), '
            'ticket:ticket_id(target_entry_group_ids)',
          )
          .eq('event_id', eventId)
          .neq('user_id', userId)
          .filter('ticket.target_entry_group_ids', 'ov', targetGroupIds);

      final candidates = (participants as List).map((dynamic p) {
        final pMap = p as Map<String, dynamic>;
        final userJson = pMap['user'] as Map<String, dynamic>;
        return UserProfile.fromJson(userJson);
      }).toList();

      return candidates;
    } catch (e, st) {
      Log.e('❌ [MatchingRepo] getMatchingCandidates Error', e, st);
      rethrow;
    }
  }
}
