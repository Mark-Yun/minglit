import 'package:supabase/supabase.dart';
import 'package:test_data_seeder/database_seeder.dart';

/// Ensures the database is seeded with initial data.
/// Returns a valid partner ID.
Future<String> ensureDatabaseSeeded(SupabaseClient adminClient) async {
  // 1. Check if partner exists
  var partnerRes =
      await adminClient.from('partners').select('id').limit(1).maybeSingle();

  if (partnerRes == null) {
    // 2. Run Seeder if no data
    print('🌱 Seeding database for test...');
    final seeder = DatabaseSeeder(adminClient);
    await seeder.seed();

    // 3. Get partner again
    partnerRes =
        await adminClient.from('partners').select('id').limit(1).maybeSingle();
  }

  if (partnerRes == null) {
    throw Exception('🚨 Test Error: Seeder failed to create a partner.');
  }
  return partnerRes['id'] as String;
}

/// Finds a Male user, Age 25 (approx), Verified.
Future<String> getMale25VerifiedUserId(SupabaseClient client) async {
  final targetBirthYear = DateTime.now().year - 25 + 1;
  final res = await client
      .from('user_profiles')
      .select('id')
      .eq('gender', 'male')
      .eq('birth_date', '$targetBirthYear-01-01')
      .like('username', '%_ok')
      .limit(1)
      .maybeSingle();

  if (res == null) {
    throw Exception(
      '🚨 Helper Error: Male/25/Verified user not found. Run seeder?',
    );
  }
  return res['id'] as String;
}

/// Finds a Female user, Age 25 (approx), Verified.
Future<String> getFemale25VerifiedUserId(SupabaseClient client) async {
  final targetBirthYear = DateTime.now().year - 25 + 1;
  final res = await client
      .from('user_profiles')
      .select('id')
      .eq('gender', 'female')
      .eq('birth_date', '$targetBirthYear-01-01')
      .like('username', '%_ok')
      .limit(1)
      .maybeSingle();

  if (res == null) {
    throw Exception(
      '🚨 Helper Error: Female/25/Verified user not found. Run seeder?',
    );
  }
  return res['id'] as String;
}

/// Finds a scheduled event and returns its context (Event, Ticket, Partner, Owner).
Future<({String eventId, String ticketId, String partnerId, String ownerId})>
    findScheduledEvent(SupabaseClient client) async {
  final eventRes = await client
      .from('events')
      .select('*, tickets(*), party:parties(*, partner:partners(*))')
      .eq('status', 'scheduled')
      .limit(1)
      .maybeSingle();

  if (eventRes == null) {
    throw Exception('🚨 Helper Error: No scheduled events found.');
  }

  final eventId = eventRes['id'] as String;
  final tickets = eventRes['tickets'] as List;
  if (tickets.isEmpty) {
    throw Exception('🚨 Helper Error: Event $eventId has no tickets.');
  }
  final ticketId = tickets[0]['id'] as String;

  final party = eventRes['party'] as Map<String, dynamic>;
  final partner = party['partner'] as Map<String, dynamic>;
  final partnerId = partner['id'] as String;

  // Find Partner Owner
  final ownerRes = await client
      .from('partner_member_permissions')
      .select('user_id')
      .eq('partner_id', partnerId)
      .eq('role', 'owner')
      .single();
  final ownerId = ownerRes['user_id'] as String;

  return (
    eventId: eventId,
    ticketId: ticketId,
    partnerId: partnerId,
    ownerId: ownerId,
  );
}

Future<String> getCareerVerificationId(SupabaseClient client) async {
  final res = await client
      .from('verifications')
      .select('id')
      .eq('category', 'career')
      .limit(1)
      .maybeSingle();

  if (res == null) {
    // Fallback to any if specific type not found
    final any =
        await client.from('verifications').select('id').limit(1).single();
    return any['id'] as String;
  }
  return res['id'] as String;
}
