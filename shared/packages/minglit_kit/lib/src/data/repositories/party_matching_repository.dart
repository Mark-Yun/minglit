part of 'party_repository.dart';

mixin _PartyMatchingRepository on _SupabasePartyContext {
  /// Replaces all entry group templates for a party.
  Future<void> replaceEntryGroupTemplates(
    String partyId,
    List<EntryGroupTemplate> templates,
  ) async {
    Log.d(
      'replaceEntryGroupTemplates called | partyId: $partyId, '
      'count: ${templates.length}',
    );
    try {
      final groupsJson = templates
          .map(
            (group) => group.copyWith(partyId: partyId).toJson()
              ..remove('created_at')
              ..remove('updated_at'),
          )
          .toList();

      final response = await supabaseClient.functions.invoke(
        'partner-manage-party',
        body: {
          'action': 'update',
          'party_id': partyId,
          'entry_group_templates': groupsJson,
        },
      );
      if (response.status != 200) {
        final error = response.data is Map
            ? (response.data as Map)['error'] ??
                  'Failed to replace entry group templates'
            : 'Failed to replace entry group templates';
        throw Exception(error);
      }
      Log.d('replaceEntryGroupTemplates success');
    } catch (e, st) {
      Log.e('❌ [PartyRepo] replaceEntryGroupTemplates Error', e, st);
      rethrow;
    }
  }
}
