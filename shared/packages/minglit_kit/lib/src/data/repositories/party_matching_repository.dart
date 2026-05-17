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
      // Fix #1740: entry_groups(Event Level)은 party_id 컬럼 없음 — entry_group_templates(Party Level) 사용
      await supabaseClient
          .from('entry_group_templates')
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

      // minglit_lints: allow-supabase-write — reason: EF migration pending (Phase 2 partner-side, tracked in #2392)
      await supabaseClient.from('entry_group_templates').insert(groupsJson);
      Log.d('replaceEntryGroupTemplates success');
    } catch (e, st) {
      Log.e('❌ [PartyRepo] replaceEntryGroupTemplates Error', e, st);
      rethrow;
    }
  }
}
