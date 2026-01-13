import 'package:postgres/postgres.dart';

void main() async {
  final connection = await Connection.open(
    Endpoint(host: '127.0.0.1', port: 54322, database: 'postgres', username: 'postgres', password: 'postgres'),
    settings: ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    print('Setting up test data...');
    // 1. Create Dummy User (if not exists)
    // Need to insert into auth.users first because of FK
    // But auth.users is protected. We can insert into user_profiles directly if we disable triggers? No, FK constraint.
    // Let's use a known ID from seed if available, or try to insert into auth.users (superuser can).
    
    final userId = 'test-user-001'; // Not UUID, might fail if UUID required.
    // UUID required.
    final userUuid = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
    final partyUuid = 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b22';
    final partnerUuid = 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380c33';

    await connection.execute("INSERT INTO auth.users (id, email) VALUES ('$userUuid', 'test@example.com') ON CONFLICT (id) DO NOTHING");
    // Trigger on auth.users will create user_profiles automatically.
    
    // 2. Create Dummy Party
    await connection.execute("INSERT INTO public.partners (id, name) VALUES ('$partnerUuid', 'Test Partner') ON CONFLICT (id) DO NOTHING");
    await connection.execute("INSERT INTO public.parties (id, partner_id, title) VALUES ('$partyUuid', '$partnerUuid', 'Test Party') ON CONFLICT (id) DO NOTHING");

    // 3. Force Insert Party Embedding (Mock Vector)
    // [0.1, 0.1, ... 1536 times]
    final vectorStr = '[' + List.filled(1536, 0.1).join(',') + ']';
    await connection.execute("INSERT INTO public.party_embeddings (party_id, embedding) VALUES ('$partyUuid', '$vectorStr') ON CONFLICT (party_id) DO UPDATE SET embedding = '$vectorStr'");

    // 4. Create Action
    print('Inserting User Action...');
    await connection.execute("INSERT INTO public.user_actions (user_id, party_id, action_type) VALUES ('$userUuid', '$partyUuid', 'like')");

    print('Test data setup complete.');
  } catch (e) {
    print('Error: $e');
  } finally {
    await connection.close();
  }
}
