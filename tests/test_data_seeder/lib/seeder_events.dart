part of 'database_seeder.dart';

mixin _SeederEvents on _SeederContext {
  Future<void> _createPartyAndEvents(
    String partnerId,
    String locationId,
    Map<String, dynamic> partyData,
    List<String> globalVerifIds,
    List<String> localVerifIds,
  ) async {
    final partyId = const Uuid().v4();

    // Map Entry Groups & Tickets from input data
    final entryGroupsList = partyData['entry_groups'] as List<dynamic>;
    final ticketsList = partyData['tickets'] as List<dynamic>;

    final allVerifIds = entryGroupsList
        .expand((e) => (e as Map)['use_global_ids'] as List? ?? [])
        .map((e) => globalVerifIds[e as int]) // Map index to real ID
        .toSet()
        .toList();

    // Calculate max participants based on ticket quantities
    final partyMaxParticipants = ticketsList.fold<int>(
      0,
      (sum, t) => sum + (t['quantity'] as int),
    );

    await adminClient.from('parties').insert({
      'id': partyId,
      'partner_id': partnerId,
      'location_id': locationId,
      'title': partyData['title'],
      'description': partyData['description'],
      'image_urls': partyData['image_url'] != null
          ? <dynamic>[partyData['image_url']]
          : <dynamic>[],
      'min_confirmed_count': (partyMaxParticipants * 0.2).floor(), // 20% of max
      'max_participants': partyMaxParticipants,
      'required_verification_ids': allVerifIds,
    });

    // ... (entry group and ticket template creation logic)

    // --- Instance Creation (Events) ---
    final now = DateTime.now();
    final eventDates = [
      now.add(const Duration(hours: 3)),
      now.add(const Duration(days: 7)),
    ];

    for (final date in eventDates) {
      final eventId = const Uuid().v4();
      await adminClient.from('events').insert({
        'id': eventId,
        'party_id': partyId,
        'location_id': locationId,
        'title': null,
        'start_time': date.toIso8601String(),
        'end_time': date.add(const Duration(hours: 4)).toIso8601String(),
        'min_confirmed_count': (partyMaxParticipants * 0.2).floor(),
        'max_participants': partyMaxParticipants,
        'status': 'scheduled',
      });

      // 1. Create Event Entry Groups
      final eventGroupsRes = await adminClient
          .from('entry_groups')
          .insert(
            entryGroupsList.map((dynamic g) {
              final gMap = g as Map<String, dynamic>;
              final reqIds = (gMap['use_global_ids'] as List? ?? [])
                  .map((i) => globalVerifIds[i as int])
                  .toList();
              return {
                'event_id': eventId,
                'label': gMap['label'],
                'gender': gMap['gender'],
                'birth_year_min': gMap['birth_year_range']?['min'],
                'birth_year_max': gMap['birth_year_range']?['max'],
                'required_verification_ids': reqIds,
              };
            }).toList(),
          )
          .select('id');
      final eventGroupIds = (eventGroupsRes as List)
          .map((e) => e['id'] as String)
          .toList();

      // 2. Create Event Tickets
      await adminClient
          .from('tickets')
          .insert(
            ticketsList.map((dynamic t) {
              final tMap = t as Map<String, dynamic>;
              final groupIdx = tMap['group_index'] as int;
              return {
                'event_id': eventId,
                'name': tMap['name'],
                'price': tMap['price'],
                'quantity': tMap['quantity'],
                'target_entry_group_ids': [eventGroupIds[groupIdx]],
                'status': 'on_sale',
              };
            }).toList(),
          );
    }
  }
}
