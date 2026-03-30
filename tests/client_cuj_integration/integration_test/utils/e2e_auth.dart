import 'package:supabase_flutter/supabase_flutter.dart';

import 'e2e_config.dart';

/// Creates a Supabase admin client that bypasses RLS.
/// Used for test setup, teardown, and data queries
/// that require elevated access.
SupabaseClient createAdminClient() {
  return SupabaseClient(
    E2eConfig.supabaseUrl,
    E2eConfig.serviceRoleKey,
    headers: {
      'Authorization': 'Bearer ${E2eConfig.serviceRoleKey}',
      'apikey': E2eConfig.serviceRoleKey,
    },
  );
}

/// Signs in to the global Supabase instance as a test user.
/// After this call, `Supabase.instance.client` is authenticated as [email].
Future<AuthResponse> signInAsTestUser(String email) async {
  return Supabase.instance.client.auth.signInWithPassword(
    email: email,
    password: E2eConfig.testPassword,
  );
}

/// Signs out the current user from the global Supabase instance.
Future<void> signOut() async {
  await Supabase.instance.client.auth.signOut();
}

/// Finds a verified seed test user's email by gender.
///
/// Queries `user_profiles` for a user matching:
/// - [gender] ('male' or 'female')
/// - birth_date = 25 years ago (seed pattern)
/// - username ending in '_ok' (verified user convention)
///
/// Then resolves their auth email via `auth.admin.getUserById`.
Future<String> getTestUserEmail(
  SupabaseClient adminClient, {
  required String gender,
}) async {
  final targetBirthYear = DateTime.now().year - 25 + 1;

  final res =
      await adminClient
          .from('user_profiles')
          .select('id')
          .eq('gender', gender)
          .eq('birth_date', '$targetBirthYear-01-01')
          .like('username', '%_ok')
          .limit(1)
          .maybeSingle();

  if (res == null) {
    throw StateError(
      'No verified $gender test user found. '
      'Expected user_profiles with gender=$gender, '
      'birth_date=$targetBirthYear-01-01, username LIKE %_ok. '
      'Run dev-seed to populate test data.',
    );
  }

  final userId = res['id'] as String;
  final userResponse = await adminClient.auth.admin.getUserById(userId);
  final email = userResponse.user?.email;

  if (email == null || email.isEmpty) {
    throw StateError(
      'Test user $userId has no email in auth.users. '
      'Seed data may be corrupted.',
    );
  }

  return email;
}

/// Finds a partner owner's email by user ID.
Future<String> getPartnerOwnerEmail(
  SupabaseClient adminClient, {
  required String ownerId,
}) async {
  final userResponse = await adminClient.auth.admin.getUserById(ownerId);
  final email = userResponse.user?.email;

  if (email == null || email.isEmpty) {
    throw StateError(
      'Partner owner $ownerId has no email in auth.users.',
    );
  }

  return email;
}
