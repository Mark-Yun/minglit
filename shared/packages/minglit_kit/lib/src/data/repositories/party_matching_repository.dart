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
      await supabaseClient
          .from('entry_groups')
          .delete()
          .eq('party_id', partyId);

      if (templates.isEmpty) return;

      final groupsJson = templates
          .map(
            (group) => group.copyWith(partyId: partyId).toJson()
              ..remove('created_at')
              ..remove('updated_at'),
          )
          .toList();

      await supabaseClient.from('entry_groups').insert(groupsJson);
      Log.d('replaceEntryGroupTemplates success');
    } catch (e, st) {
      Log.e('❌ [PartyRepo] replaceEntryGroupTemplates Error', e, st);
      rethrow;
    }
  }
}
