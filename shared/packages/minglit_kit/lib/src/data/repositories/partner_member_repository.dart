part of 'partner_repository.dart';

mixin _PartnerMemberRepository on _SupabasePartnerContext {
  /// Fetches members belonging to a specific partner.
  Future<List<Map<String, dynamic>>> getPartnerMembers(
    String partnerId,
  ) async {
    Log.d('getPartnerMembers called | partnerId: $partnerId');
    try {
      final data = await supabaseClient.rpc<dynamic>(
        'get_partner_members_with_user',
        params: {'p_partner_id': partnerId},
      ) as List;
      final result = data.map((entry) {
        final map = entry as Map<String, dynamic>;
        // RPC returns flat columns: user_id, partner_id, role,
        // permissions, joined_at, user_name, user_profile_image

        // Build nested 'user' map to match caller expectations
        return <String, dynamic>{
          ...map,
          'user': {
            'id': map['user_id'],
            'name': map['user_name'],
            'email': '',
            'profile_image': map['user_profile_image'],
          },
        };
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
      await supabaseClient
          .from('partner_member_permissions')
          .update({'role': role}).match(
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
      await supabaseClient
          .from('partner_member_permissions')
          .update({'permissions': permissions}).match(
        {'partner_id': partnerId, 'user_id': userId},
      );
      Log.d('updateMemberPermissions success');
    } catch (e, st) {
      Log.e('❌ [PartnerRepo] updateMemberPermissions Error', e, st);
      rethrow;
    }
  }
}
