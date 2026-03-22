import 'package:supabase_flutter/supabase_flutter.dart';

import 'e2e_config.dart';

/// Creates a Supabase admin client that bypasses RLS.
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

/// Finds a partner owner's email by user ID.
Future<String> getPartnerOwnerEmail(
  SupabaseClient adminClient, {
  required String ownerId,
}) async {
  final userResponse =
      await adminClient.auth.admin.getUserById(ownerId);
  final email = userResponse.user?.email;

  if (email == null || email.isEmpty) {
    throw StateError(
      'Partner owner $ownerId has no email in auth.users.',
    );
  }

  return email;
}
